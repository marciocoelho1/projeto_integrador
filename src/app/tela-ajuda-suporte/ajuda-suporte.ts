import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Chamado, ChamadoService, ChamadoStatus } from '../service/chamado.service';
import { ToastService } from '../service/toast.service';
import { mensagemErroApi } from '../service/api-error';

@Component({
  selector: 'app-ajuda-suporte',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './ajuda-suporte.html',
  styleUrl: './ajuda-suporte.scss'
})
export class AjudaSuporte implements OnInit {
  private readonly chamados = inject(ChamadoService);
  private readonly toast = inject(ToastService);

  tipoSolicitacao = 'Solicitar Ajuda';
  descricao = '';

  readonly solicitacoes = signal<Chamado[]>([]);
  readonly carregando = signal(false);
  readonly statusOpcoes: ChamadoStatus[] = ['Em andamento', 'Concluída', 'Cancelada'];

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);

    this.chamados.listar().subscribe({
      next: (lista) => {
        this.solicitacoes.set(lista);
        this.carregando.set(false);
      },
      error: (erro) => {
        this.carregando.set(false);
        this.toast.error(mensagemErroApi(erro));
      },
    });
  }

  enviarSolicitacao(): void {
    const descricao = this.descricao.trim();

    if (!descricao) {
      return;
    }

    this.chamados
      .criar({
        tipo: this.tipoSolicitacao.includes('Ajuda') ? 'Ajuda' : 'Erro',
        descricao,
      })
      .subscribe({
        next: (criado) => {
          this.solicitacoes.update((lista) => [criado, ...lista]);
          this.descricao = '';
          this.toast.success('Solicitação enviada com sucesso!');
        },
        error: (erro) => this.toast.error(mensagemErroApi(erro)),
      });
  }

  mudarStatus(chamado: Chamado, status: ChamadoStatus): void {
    if (status === chamado.status) {
      return;
    }

    this.chamados
      .atualizarStatus(chamado.id, {
        tipo: chamado.tipo,
        descricao: chamado.descricao,
        status,
      })
      .subscribe({
        next: (atualizado) =>
          this.solicitacoes.update((lista) =>
            lista.map((item) => (item.id === atualizado.id ? atualizado : item)),
          ),
        error: (erro) => this.toast.error(mensagemErroApi(erro)),
      });
  }
}
