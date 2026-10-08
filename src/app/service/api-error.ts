import { HttpErrorResponse } from '@angular/common/http';

interface ApiErrorBody {
  mensagem?: string;
  detalhes?: string[];
}

export function mensagemErroApi(erro: HttpErrorResponse): string {
  if (erro.status === 0) {
    return 'Não foi possível acessar a API. Confira se o backend está iniciado.';
  }

  const body: ApiErrorBody | null =
    erro.error && typeof erro.error === 'object'
      ? erro.error as ApiErrorBody
      : null;

  if (Array.isArray(body?.detalhes) && body.detalhes.length > 0) {
    return body.detalhes.join(' ');
  }

  return body?.mensagem ?? 'Não foi possível concluir a operação.';
}
