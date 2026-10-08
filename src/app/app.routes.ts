import { Routes } from '@angular/router';
import { Login } from './tela-login/login';
import { RecuperarSenhaComponent } from './tela-recuperar-senha/recuperar-senha';
import { HelpSupportComponent } from './tela-ajuda-suporte-colaborador/ajuda-suporte-colaborador';
import { AreaColaborador } from './tela-area-colaborador/area-colaborador'; 
import { Configuracoes } from './tela-configuracoes/configuracoes';
import { LayoutPadrao } from './layout-padrao/layout-padrao';
import { Colaboradores } from './tela-colaboradores/colaboradores';
import { Epis } from './tela-epis/epis'; 
import { Cadastramentos } from './tela-cadastramentos/cadastramentos'; 
import { Dashboard } from './tela-dashboard/dashboard';
import { MatrizTreinamentos } from './tela-matriz-treinamento/matriz-treinamento';
import { AjudaSuporte } from './tela-ajuda-suporte/ajuda-suporte';
import { authGuard } from './auth.guard'; 
import { ImportacaoMassa } from './tela-importacao-massa/importacao-massa';

export const routes: Routes = [
  
  { path: 'login', component: Login },
  { path: 'recuperar-senha', component: RecuperarSenhaComponent },

  
  {
    path: '',
    component: LayoutPadrao,
    canActivate: [authGuard], 
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', component: Dashboard },
      { path: 'area-colaborador', component: AreaColaborador }, 
      { path: 'colaboradores', component: Colaboradores },
      { path: 'epis', component: Epis },
      { path: 'matriz-treinamentos', component: MatrizTreinamentos },
      { path: 'cadastramentos', component: Cadastramentos },
      { path: 'importacao-massa', component: ImportacaoMassa },
      { path: 'ajuda-suporte', component: AjudaSuporte },
      { path: 'ajuda-suporte-colaborador', component: HelpSupportComponent },
      { path: 'configuracoes', component: Configuracoes },
    ]
  },

  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: '**', redirectTo: 'login' }
];