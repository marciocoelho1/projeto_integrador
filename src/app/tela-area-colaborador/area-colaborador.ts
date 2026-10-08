import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

interface Certificacao {
  treinamento: string;
  validade: string;
  status: 'Ativa' | 'Vencida';
}

interface MaterialReciclagem {
  treinamento: string;
  prazo: string;
  link: string;
}

interface EpiRecebido {
  id: string;
  nome: string;
  quantidade: number;
  ca: string;
  dataEntrega: string;
  assinatura: string;
}

@Component({
  selector: 'app-area-colaborador',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './area-colaborador.html',
  styleUrls: ['./area-colaborador.scss'],
})
export class AreaColaborador {
  resumo = {
    certificacoes: 1,
    reciclagens: 1,
    epis: 2,
  };

  minhasCertificacoes: Certificacao[] = [
    { treinamento: 'NR-35 Trabalho em Altura', validade: '10/07/2026', status: 'Vencida' },
  ];

  materiaisReciclagem: MaterialReciclagem[] = [
    { treinamento: 'NR-35 Trabalho em Altura', prazo: '12/06/2026', link: 'https://youtube.com' },
  ];

  meusEpis: EpiRecebido[] = [
    {
      id: 'EPI-001',
      nome: 'Capacete de Segurança',
      quantidade: 1,
      ca: '498',
      dataEntrega: '01/06/2026',
      assinatura: 'Colaborador',
    },
    {
      id: 'EPI-002',
      nome: 'Óculos de Segurança',
      quantidade: 2,
      ca: '18.103',
      dataEntrega: '01/06/2026',
      assinatura: 'Colaborador',
    },
  ];
}
