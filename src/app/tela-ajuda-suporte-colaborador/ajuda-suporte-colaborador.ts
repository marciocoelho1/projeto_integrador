import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../auth.service';
import { ToastService } from '../service/toast.service';

export interface SupportRequest {
  id: number;
  type: string;
  description: string;
  ownerMatricula: string;
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
export class HelpSupportComponent {
  private toast = inject(ToastService);
  private authService = inject(AuthService);
  private nextRequestId = 2;

  ticketType: string = 'Solicitar Ajuda';
  ticketDescription: string = '';

  readonly requests = signal<SupportRequest[]>([
    {
      id: 1,
      type: 'Ajuda',
      description: 'Dúvida sobre renovação de NR-10',
      ownerMatricula: 'colaborador',
      user: 'Colaborador',
      status: 'Em andamento',
    },
  ]);

  get visibleRequests(): SupportRequest[] {
    const currentUser = this.authService.getCurrentUser();

    if (!currentUser) {
      return [];
    }

    return this.requests().filter((request) => request.ownerMatricula === currentUser.matricula);
  }

  handleSubmit(): void {
    const currentUser = this.authService.getCurrentUser();

    if (!currentUser) {
      this.toast.error('Não foi possível identificar o usuário autenticado. Entre novamente.');
      return;
    }

    if (!this.ticketDescription.trim()) {
      this.toast.error('Preencha a descrição da solicitação.');
      return;
    }

    const newRequest: SupportRequest = {
      id: this.nextRequestId++,
      type: this.ticketType.includes('Ajuda') ? 'Ajuda' : 'Erro',
      description: this.ticketDescription.trim(),
      ownerMatricula: currentUser.matricula,
      user: currentUser.nomeExibicao,
      status: 'Em andamento',
    };

    this.requests.update((requests) => [newRequest, ...requests]);
    this.ticketDescription = '';
    this.toast.success('Solicitação enviada com sucesso!');
  }
}
