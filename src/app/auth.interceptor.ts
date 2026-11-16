import {
  HttpErrorResponse,
  HttpInterceptorFn,
} from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { AuthService } from './auth.service';

/**
 * Envia o token da sessão em toda requisição e, se a API responder 401 com uma sessão local
 * ativa (token expirado, sessão revogada), limpa a sessão e volta para o login.
 */
export const authInterceptor: HttpInterceptorFn = (requisicao, proximo) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  const token = auth.getToken();

  const comToken = token
    ? requisicao.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : requisicao;

  return proximo(comToken).pipe(
    catchError((erro: HttpErrorResponse) => {
      if (erro.status === 401 && auth.isLoggedIn()) {
        auth.limparSessaoLocal();
        void router.navigate(['/login']);
      }

      return throwError(() => erro);
    }),
  );
};
