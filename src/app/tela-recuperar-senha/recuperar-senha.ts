import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

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

  handleSubmit(): void {
    const payload: RecoverPasswordPayload = {
      matricula: this.matricula.trim(),
      email: this.email.trim()
    };

    if (this.validatePayload(payload)) {
      this.sendRecoveryRequest(payload);
    }
  }

  private validatePayload(payload: RecoverPasswordPayload): boolean {
    if (!payload.matricula) {
      alert('Por favor, informe a matrícula.');
      return false;
    }

    if (!payload.email || !payload.email.includes('@')) {
      alert('Por favor, informe um e-mail válido.');
      return false;
    }

    return true;
  }

  private sendRecoveryRequest(payload: RecoverPasswordPayload): void {
    console.log('Enviando dados de recuperação:', payload);
    alert(`Instruções enviadas para o e-mail: ${payload.email}`);
  }
}