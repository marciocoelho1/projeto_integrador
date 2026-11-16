import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../auth.service';
import { ColaboradorService } from '../service/colaborador.service';
import { EpisService, EntregaEpi } from '../service/epis.service';
import { Colaborador } from '../models/colaborador.model';
import { mensagemErroApi } from '../service/api-error';

interface Certificacao {
  treinamento: string;
  validade: string;
  status: 'Ativa' | 'Vencida';
}

interface MaterialReciclagem {
  treinamento: string;
  prazo: string;
  link: string;
}

interface EpiRecebido {
  id: string;
  nome: string;
  quantidade: number;
  ca: string;
  dataEntrega: string;
  assinatura: string;
}

const SEM_VINCULO =
  'Não localizamos um cadastro de colaborador vinculado ao seu login. Procure o SESMT para conferir sua matrícula.';

@Component({
  selector: 'app-area-colaborador',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './area-colaborador.html',
  styleUrls: ['./area-colaborador.scss'],
})
export class AreaColaborador implements OnInit {
  private readonly auth = inject(AuthService);
  private readonly apiColaboradores = inject(ColaboradorService);
  private readonly apiEpis = inject(EpisService);

  resumo = {
    certificacoes: 1,
    reciclagens: 1,
    epis: 0,
  };

  minhasCertificacoes: Certificacao[] = [
    { treinamento: 'NR-35 Trabalho em Altura', validade: '10/07/2026', status: 'Vencida' },
  ];

  materiaisReciclagem: MaterialReciclagem[] = [
    { treinamento: 'NR-35 Trabalho em Altura', prazo: '12/06/2026', link: 'https://youtube.com' },
  ];

  /** Entregas reais do colaborador logado (GET /api/entregas-epis?colaboradorId=...). */
  meusEpis: EpiRecebido[] = [];

  carregandoEpis = false;

  /** Mensagem explicativa do estado vazio; vazia quando há entregas reais. */
  avisoEpis = '';

  ngOnInit() {
    this.carregarMeusEpis();
  }

  carregarMeusEpis() {
    if (this.carregandoEpis) return;
    this.carregandoEpis = true;
    this.avisoEpis = '';
    // Não existe FK usuário↔colaborador: casamos a matrícula do login (ou o e-mail, quando o
    // login é um e-mail) com o cadastro de colaboradores e só então buscamos as entregas.
    this.apiColaboradores.listar().subscribe({
      next: (colaboradores) => {
        const colaborador = this.resolverColaborador(colaboradores);
        if (!colaborador) {
          this.meusEpis = [];
          this.resumo.epis = 0;
          this.avisoEpis = SEM_VINCULO;
          this.carregandoEpis = false;
          return;
        }
        this.carregarEntregas(colaborador.id);
      },
      error: (erro) => {
        this.avisoEpis = mensagemErroApi(erro);
        this.carregandoEpis = false;
      },
    });
  }

  private carregarEntregas(colaboradorId: number) {
    this.apiEpis.obterEntregas(colaboradorId).subscribe({
      next: (entregas) => {
        this.meusEpis = entregas.map((entrega) => this.paraEpiRecebido(entrega));
        this.resumo.epis = this.meusEpis.length;
        this.avisoEpis = this.meusEpis.length === 0 ? 'Nenhum EPI registrado no momento.' : '';
        this.carregandoEpis = false;
      },
      error: (erro) => {
        this.avisoEpis = mensagemErroApi(erro);
        this.carregandoEpis = false;
      },
    });
  }

  private resolverColaborador(colaboradores: Colaborador[]): Colaborador | undefined {
    const chave = this.auth.getCurrentUser()?.matricula?.trim().toLowerCase();
    if (!chave) return undefined;
    const normalizado = (valor: string) => valor.trim().toLowerCase();
    return (
      colaboradores.find((colaborador) => normalizado(colaborador.matricula) === chave) ??
      colaboradores.find((colaborador) => normalizado(colaborador.email) === chave)
    );
  }

  private paraEpiRecebido(entrega: EntregaEpi): EpiRecebido {
    return {
      id: entrega.id != null ? String(entrega.id) : '',
      nome: entrega.epi ?? '',
      quantidade: entrega.quantidade ?? 0,
      ca: entrega.ca ?? '',
      dataEntrega: entrega.dataEntrega ?? '',
      assinatura: entrega.assinatura ?? '',
    };
  }
}
