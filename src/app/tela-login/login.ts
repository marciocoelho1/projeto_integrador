import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService, perfilDoGrupo } from '../auth.service';
import { mensagemErroApi } from '../service/api-error';

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
  mensagemErro = '';
  entrando = false;

  private router = inject(Router);
  private authService = inject(AuthService);

  entrar() {
    if (this.entrando) {
      return;
    }

    const login = this.email.trim();

    if (!login || !this.senha) {
      this.erroLogin = true;
      this.mensagemErro = 'Informe o usuário e a senha.';
      return;
    }

    this.entrando = true;
    this.erroLogin = false;
    this.mensagemErro = '';

    this.authService.entrar(login, this.senha).subscribe({
      next: (resposta) => {
        this.entrando = false;
        this.router.navigate([
          perfilDoGrupo(resposta.usuario.grupo) === 'admin'
            ? '/dashboard'
            : '/area-colaborador',
        ]);
      },
      error: (erro) => {
        this.entrando = false;
        this.erroLogin = true;
        this.mensagemErro = mensagemErroApi(erro);
      },
    });
  }

  irParaRecuperarSenha(event: Event) {
    event.preventDefault();
    this.router.navigate(['/recuperar-senha']);
  }
}
