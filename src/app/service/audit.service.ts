import { Injectable, signal } from '@angular/core';

export interface LogAuditoria {
  id: number;
  dataHora: string;
  usuario: string; 
  modulo: string;
  acao: 'CRIACAO' | 'EDICAO' | 'EXCLUSAO' | 'ACESSO' | 'ALERTA';
  descricao: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuditService {
  private nextId = 4;
  
  
  logs = signal<LogAuditoria[]>([
    { id: 1, dataHora: '2026-08-12T13:30:00', usuario: 'Marcio Coelho Elias Junior', modulo: 'Cadastramentos', acao: 'CRIACAO', descricao: 'Cadastrou o EPI Capacete de Segurança' },
    { id: 2, dataHora: '2026-08-12T09:15:00', usuario: 'Administrador TST', modulo: 'Configurações', acao: 'EDICAO', descricao: 'Alterou permissões do grupo Colaborador' },
    { id: 3, dataHora: '2026-08-11T16:45:00', usuario: 'Marcio Coelho Elias Junior', modulo: 'Login', acao: 'ACESSO', descricao: 'Login no sistema realizado com sucesso' }
  ]);

  
  registrarAcao(usuario: string, modulo: string, acao: LogAuditoria['acao'], descricao: string) {
    const novoLog: LogAuditoria = {
      id: this.nextId++,
      dataHora: new Date().toISOString(), 
      usuario,
      modulo,
      acao,
      descricao
    };
    
    
    this.logs.update(current => [novoLog, ...current]);
  }
}