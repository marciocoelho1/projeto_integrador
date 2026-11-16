import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Chamado, ChamadoService } from '../service/chamado.service';
import { ToastService } from '../service/toast.service';
import { mensagemErroApi } from '../service/api-error';

export interface SupportRequest {
  id: number;
  type: string;
  description: string;
  user: string;
  status: string;
}

@Component({
  selector: 'app-ajuda-suporte-colaborador',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './ajuda-suporte-colaborador.html',
  styleUrls: ['./ajuda-suporte-colaborador.scss'],
})
export class HelpSupportComponent implements OnInit {
  private readonly chamados = inject(ChamadoService);
  private readonly toast = inject(ToastService);

  ticketType: string = 'Solicitar Ajuda';
  ticketDescription: string = '';

  /** Somente os chamados do usuário da sessão (GET /api/chamados?meus=true). */
  readonly requests = signal<SupportRequest[]>([]);
  readonly carregando = signal(false);

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);

    this.chamados.listar({ meus: true }).subscribe({
      next: (lista) => {
        this.requests.set(lista.map(paraSupportRequest));
        this.carregando.set(false);
      },
      error: (erro) => {
        this.carregando.set(false);
        this.toast.error(mensagemErroApi(erro));
      },
    });
  }

  handleSubmit(): void {
    const descricao = this.ticketDescription.trim();

    if (!descricao) {
      this.toast.error('Preencha a descrição da solicitação.');
      return;
    }

    this.chamados
      .criar({
        tipo: this.ticketType.includes('Ajuda') ? 'Ajuda' : 'Erro',
        descricao,
      })
      .subscribe({
        next: (criado) => {
          this.requests.update((lista) => [paraSupportRequest(criado), ...lista]);
          this.ticketDescription = '';
          this.toast.success('Solicitação enviada com sucesso!');
        },
        error: (erro) => this.toast.error(mensagemErroApi(erro)),
      });
  }
}

function paraSupportRequest(chamado: Chamado): SupportRequest {
  return {
    id: chamado.id,
    type: chamado.tipo,
    description: chamado.descricao,
    user: chamado.solicitante,
    status: chamado.status,
  };
}
