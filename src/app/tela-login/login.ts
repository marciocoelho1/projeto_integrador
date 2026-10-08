import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, RouterLink],
  templateUrl: './login.html',
  styleUrl: './login.scss',
})
export class Login {
  email = '';
  senha = '';
  erroLogin = false;

  private router = inject(Router);
  private authService = inject(AuthService);

  entrar() {
    if (this.email === 'admin' && this.senha === '123456') {
      this.erroLogin = false;
      this.authService.setSession('admin', {
        matricula: this.email,
        nomeExibicao: 'Administrador TST',
      });
      this.router.navigate(['/dashboard']);
    } else if (this.email === 'colaborador' && this.senha === '123456') {
      this.erroLogin = false;
      this.authService.setSession('colaborador', {
        matricula: this.email,
        nomeExibicao: 'Colaborador',
      });
      this.router.navigate(['/area-colaborador']);
    } else {
      this.erroLogin = true;
    }
  }

  irParaRecuperarSenha(event: Event) {
    event.preventDefault();
    this.router.navigate(['/recuperar-senha']);
  }
}
