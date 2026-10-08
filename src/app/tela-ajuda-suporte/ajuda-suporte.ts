import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

interface Solicitacao {
  tipo: string;
  descricao: string;
  usuario: string;
  status: string;
}

@Component({
  selector: 'app-ajuda-suporte',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './ajuda-suporte.html',
  styleUrl: './ajuda-suporte.scss'
})
export class AjudaSuporte {
  tipoSolicitacao = 'Solicitar Ajuda';
  descricao = '';

  solicitacoes: Solicitacao[] = [
    {
      tipo: 'Ajuda',
      descricao: 'Dúvida sobre renovação de NR-10',
      usuario: 'João da Silva',
      status: 'Em andamento'
    },
    {
      tipo: 'Erro',
      descricao: 'Erro ao gerar relatório de EPIs',
      usuario: 'Maria Joana',
      status: 'Concluída'
    }
  ];

  enviarSolicitacao(): void {
    if (this.descricao.trim()) {
      this.solicitacoes.unshift({
        tipo: this.tipoSolicitacao.includes('Ajuda') ? 'Ajuda' : 'Erro',
        descricao: this.descricao,
        usuario: 'Usuário Atual',
        status: 'Em andamento'
      });
      this.descricao = '';
    }
  }
}