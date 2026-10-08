import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.html',
  styleUrls: ['./dashboard.scss']
})
export class Dashboard {
  
  protected readonly alertas = [
    { tipo: 'EPI', mensagem: '12 Botinas de Segurança vencem esta semana.', criticidade: 'alta' },
    { tipo: 'Treinamento', mensagem: 'NR-35 pendente para 5 colaboradores da Logística.', criticidade: 'media' },
    { tipo: 'Certificação', mensagem: 'Renovação do PPRA concluída.', criticidade: 'baixa' }
  ];

  
  protected readonly certificacoes = {
    ativas: 142,
    vencidas: 18
  };

  
  protected readonly epis = {
    aEntregar: 25,
    emEstoque: 140,
    proximoVencimento: 12
  };

  
  protected readonly reciclagens = {
    concluidas: 42,
    pendentes: 18,
    total: 60,
    porcentagem: 70
  };

  protected exportarRelatorio(): void {
    const totalCertificacoes = this.certificacoes.ativas + this.certificacoes.vencidas;
    const totalEpis = this.epis.aEntregar + this.epis.emEstoque + this.epis.proximoVencimento;

    const linhas = [
      'Categoria,Metrica,Valor',
      `Certificações,Ativas,${this.certificacoes.ativas}`,
      `Certificações,Vencidas,${this.certificacoes.vencidas}`,
      `Certificações,Total,${totalCertificacoes}`,
      `EPIs,A Entregar,${this.epis.aEntregar}`,
      `EPIs,Em Estoque,${this.epis.emEstoque}`,
      `EPIs,Próximo ao Vencimento,${this.epis.proximoVencimento}`,
      `EPIs,Total,${totalEpis}`,
      `Reciclagens,Concluídas,${this.reciclagens.concluidas}`,
      `Reciclagens,Pendentes,${this.reciclagens.pendentes}`,
      `Reciclagens,Total,${this.reciclagens.total}`,
      `Reciclagens,Porcentagem,${this.reciclagens.porcentagem}%`
    ];

    const csvContent = '\uFEFF' + linhas.join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    link.setAttribute('href', url);
    link.setAttribute('download', 'relatorio_dashboard.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }
}
