import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';

import { routes } from './app.routes';
import { authInterceptor } from './auth.interceptor';
import { environment } from '../environments/environment';
import { demoApiInterceptor } from './demo/demo-api.interceptor';

/**
 * No modo demonstração (`npm run demo`) o backend é substituído pela API em memória: o
 * `demoApiInterceptor` responde `/api/**` e o `authInterceptor` continua enviando o token da
 * sessão, como no build normal.
 */
export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient(
      withInterceptors(
        environment.demo ? [authInterceptor, demoApiInterceptor] : [authInterceptor],
      ),
    ),
  ],
};
