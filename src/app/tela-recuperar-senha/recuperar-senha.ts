import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { ToastService } from '../service/toast.service';
import { mensagemErroApi } from '../service/api-error';

export interface RecoverPasswordPayload {
  matricula: string;
  email: string;
}

@Component({
  selector: 'app-recuperar-senha',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './recuperar-senha.html',
  styleUrl: './recuperar-senha.scss'
})
export class RecuperarSenhaComponent {
  matricula: string = '';
  email: string = '';
  enviando = false;

  private readonly http = inject(HttpClient);
  private readonly toast = inject(ToastService);

  handleSubmit(): void {
    if (this.enviando) {
      return;
    }

    const payload: RecoverPasswordPayload = {
      matricula: this.matricula.trim(),
      email: this.email.trim()
    };

    if (!payload.matricula && !payload.email) {
      this.toast.error('Informe a matrícula ou o e-mail cadastrado.');
      return;
    }

    this.enviando = true;

    this.http
      .post<{ mensagem: string }>(
        `${environment.apiBaseUrl}/auth/recuperar-senha`,
        { login: payload.matricula || payload.email },
      )
      .subscribe({
        next: (resposta) => {
          this.enviando = false;
          this.toast.success(resposta.mensagem);
          this.matricula = '';
          this.email = '';
        },
        error: (erro) => {
          this.enviando = false;
          this.toast.error(mensagemErroApi(erro));
        },
      });
  }
}
