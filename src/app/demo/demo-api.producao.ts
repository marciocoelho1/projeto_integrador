import { HttpInterceptorFn } from '@angular/common/http';

/**
 * Versão do interceptador de demonstração usada no build de produção.
 *
 * O `angular.json` troca `demo-api.interceptor.ts` por este arquivo na configuração `production`,
 * então os dados de exemplo (`demo-dados.ts`) não entram no bundle publicado. A assinatura é a
 * mesma para o `app.config.ts` continuar compilando nos dois casos.
 */
export const demoApiInterceptor: HttpInterceptorFn = (requisicao, proximo) => proximo(requisicao);
