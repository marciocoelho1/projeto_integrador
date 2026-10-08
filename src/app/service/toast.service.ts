import { Injectable, signal } from '@angular/core';

export type ToastType = 'sucesso' | 'erro' | 'alerta';

export interface Toast {
  id: number;
  mensagem: string;
  tipo: ToastType;
}

@Injectable({
  providedIn: 'root'
})
export class ToastService {
  toasts = signal<Toast[]>([]);
  private nextId = 0;

  show(mensagem: string, tipo: ToastType = 'sucesso') {
    const id = this.nextId++;
    const newToast: Toast = { id, mensagem, tipo };
    
    
    this.toasts.update(current => [...current, newToast]);

    
    setTimeout(() => {
      this.remove(id);
    }, 4000);
  }

  
  success(mensagem: string) { this.show(mensagem, 'sucesso'); }
  error(mensagem: string) { this.show(mensagem, 'erro'); }
  warning(mensagem: string) { this.show(mensagem, 'alerta'); }

  remove(id: number) {
    this.toasts.update(current => current.filter(t => t.id !== id));
  }
}