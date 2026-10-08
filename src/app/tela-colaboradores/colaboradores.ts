import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Router } from '@angular/router';
import { ToastService } from '../service/toast.service';

interface Colaborador {
  matricula: string;
  nome: string;
  email: string;
  cargo: string;
  setor: string;
  status: 'Ativo' | 'Inativo' | 'Afastado';
}

@Component({
  selector: 'app-colaboradores',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './colaboradores.html',
  styleUrls: ['./colaboradores.scss'],
})
export class Colaboradores implements OnInit {
  termoBusca: string = '';
  private router = inject(Router);
  private toast = inject(ToastService);

  mostrarModalDetalhes: boolean = false;
  colaboradorEmEdicao: Colaborador | null = null;

  colaboradores: Colaborador[] = [
    {
      matricula: '123.456.789-00',
      nome: 'Carlos Eduardo Silva',
      email: 'carlos.silva@essenza.com.br',
      cargo: 'Operador de Empilhadeira',
      setor: 'Estoque',
      status: 'Ativo',
    },
    {
      matricula: '111.222.333-44',
      nome: 'Maria Joana Oliveira',
      email: 'maria.oliveira@essenza.com.br',
      cargo: 'Açougueira',
      setor: 'Açougue',
      status: 'Ativo',
    },
    {
      matricula: '999.888.777-66',
      nome: 'Roberto Alves',
      email: 'roberto.alves@essenza.com.br',
      cargo: 'Operador de Caixa',
      setor: 'Frente de Loja',
      status: 'Afastado',
    },
    {
      matricula: '444.555.666-77',
      nome: 'Ana Paula Souza',
      email: 'ana.souza@essenza.com.br',
      cargo: 'Repositora',
      setor: 'Mercearia',
      status: 'Ativo',
    },
    {
      matricula: '888.777.666-55',
      nome: 'Fernando Costa',
      email: 'fernando.costa@essenza.com.br',
      cargo: 'Padeiro',
      setor: 'Padaria',
      status: 'Inativo',
    },
  ];

  episColaborador: Record<string, { nome: string; dataEntrega: string; ca: string }[]> = {
    'Carlos Eduardo Silva': [
      { nome: 'Capacete de Segurança', dataEntrega: '15/01/2026', ca: '12345' },
      { nome: 'Luva de Vaqueta', dataEntrega: '15/01/2026', ca: '89765' },
    ],
    'Maria Joana Oliveira': [
      { nome: 'Luva de Malha de Aço', dataEntrega: '10/02/2025', ca: '44321' },
    ],
  };

  treinamentosColaborador: Record<
    string,
    { treinamento: string; validade: string; status: string }[]
  > = {
    'Carlos Eduardo Silva': [
      {
        treinamento: 'NR-11 Operação Segura de Empilhadeira',
        validade: '14/01/2027',
        status: 'Ativa',
      },
      { treinamento: 'NR-06 Uso de EPIs', validade: '15/01/2027', status: 'Ativa' },
    ],
    'Maria Joana Oliveira': [
      { treinamento: 'NR-12 Segurança em Máquinas', validade: '09/02/2026', status: 'Vencida' },
    ],
  };

  reciclagensColaborador: Record<string, { treinamento: string; prazo: string; status: string }[]> =
    {
      'Maria Joana Oliveira': [
        { treinamento: 'NR-12 Segurança em Máquinas', prazo: '28/02/2026', status: 'Pendente' },
      ],
    };

  constructor() {}

  ngOnInit(): void {}

  get colaboradoresFiltrados(): Colaborador[] {
    const termo = this.termoBusca.trim().toLowerCase();
    if (!termo) {
      return this.colaboradores;
    }

    return this.colaboradores.filter((c) => {
      const nome = c.nome.toLowerCase();
      const cpfMatricula = c.matricula.toLowerCase();
      const cargo = c.cargo.toLowerCase();
      const setor = c.setor.toLowerCase();
      const status = c.status.toLowerCase();

      return (
        nome.includes(termo) ||
        cpfMatricula.includes(termo) ||
        cargo.includes(termo) ||
        setor.includes(termo) ||
        status.includes(termo)
      );
    });
  }

  abrirModalDetalhes(colaborador: Colaborador): void {
    this.colaboradorEmEdicao = { ...colaborador };
    this.mostrarModalDetalhes = true;
  }

  fecharModalDetalhes(): void {
    this.mostrarModalDetalhes = false;
    this.colaboradorEmEdicao = null;
  }

  salvarEdicaoDetalhes(formulario: NgForm): void {
    if (!this.colaboradorEmEdicao) return;

    const emailValido = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.colaboradorEmEdicao.email.trim());

    if (formulario.invalid || !emailValido) {
      formulario.control.markAllAsTouched();
      const mensagem =
        formulario.controls['email']?.invalid || !emailValido
          ? 'Informe um e-mail corporativo válido.'
          : 'Preencha todos os campos obrigatórios.';
      this.toast.error(mensagem);
      return;
    }

    const index = this.colaboradores.findIndex(
      (c) => c.matricula === this.colaboradorEmEdicao!.matricula,
    );
    if (index !== -1) {
      this.colaboradores[index] = { ...this.colaboradorEmEdicao };
      this.toast.success(
        `Dados do colaborador "${this.colaboradorEmEdicao.nome}" salvos com sucesso!`,
      );
    }
    this.fecharModalDetalhes();
  }

  actionVerDetalhes(colaborador: Colaborador): void {
    this.abrirModalDetalhes(colaborador);
  }

  obterEpis(nome: string): { nome: string; dataEntrega: string; ca: string }[] {
    return this.episColaborador[nome] || [];
  }

  obterTreinamentos(nome: string): { treinamento: string; validade: string; status: string }[] {
    return this.treinamentosColaborador[nome] || [];
  }

  obterReciclagens(nome: string): { treinamento: string; prazo: string; status: string }[] {
    return this.reciclagensColaborador[nome] || [];
  }

  actionNovoColaborador(): void {
    console.log('Navegando para o cadastro de novo colaborador...');
    this.router.navigate(['/cadastramentos'], { queryParams: { aba: 'colaborador' } });
  }
}
