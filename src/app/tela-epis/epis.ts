import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { ToastService } from '../service/toast.service';
import { AuditService } from '../service/audit.service';

interface Epi {
  id: string;
  descricao: string;
  quantidade: number;
  inclusao: string;
  validade: string;
  ca: string;
}

interface EntregaEpi {
  colaborador: string;
  epi: string;
  quantidade?: number;
  data: string;
  validadeCa?: string;
  numeroCa?: string;
  assinatura: string;
}

@Component({
  selector: 'app-epis',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './epis.html',
  styleUrls: ['./epis.scss']
})
export class Epis {
  private router = inject(Router);
  private toast = inject(ToastService);
  private auditService = inject(AuditService);

  termoBusca: string = '';

  
  readonly listaEpisCadastrados: string[] = [
    'Capacete de Segurança',
    'Luva de Vaqueta',
    'Óculos de Segurança',
    'Luva de Malha de Aço',
    'Botina de Segurança',
    'Protetor Auricular',
    'Avental de PVC',
    'Máscara PFF2'
  ];

  epis: Epi[] = [
    { id: 'EPI-01', descricao: 'Capacete de Segurança', quantidade: 45, inclusao: '01/02/2026', validade: '03/02/2028', ca: '12345' },
    { id: 'EPI-02', descricao: 'Luva de Vaqueta', quantidade: 84, inclusao: '03/02/2026', validade: '03/02/2028', ca: '89765' },
    { id: 'EPI-03', descricao: 'Óculos de Segurança', quantidade: 100, inclusao: '03/02/2026', validade: '03/02/2028', ca: '23456' }
  ];

  
  entregas: EntregaEpi[] = [
    { colaborador: 'João Souza', epi: 'Capacete de Segurança', quantidade: 1, validadeCa: '03/02/2028', numeroCa: '12345', data: '01/06/2026', assinatura: 'João Souza' }
  ];

  
  
  
  mostrarModalEdicao = false;
  epiEmEdicao: Epi = { id: '', descricao: '', quantidade: 0, inclusao: '', validade: '', ca: '' };

  abrirModalEdicao(epi: Epi) {
    
    this.epiEmEdicao = { ...epi };
    this.mostrarModalEdicao = true;
  }

  fecharModalEdicao() {
    this.mostrarModalEdicao = false;
  }

  salvarEdicao() {
    const descricao = this.epiEmEdicao.descricao.trim();
    const existe = this.listaEpisCadastrados.some(e => e.toLowerCase() === descricao.toLowerCase());

    if (!existe) {
      this.toast.error(`A descrição "${descricao}" não corresponde a um EPI cadastrado no sistema.`);
      return;
    }

    const index = this.epis.findIndex(e => e.id === this.epiEmEdicao.id);
    if (index !== -1) {
      this.epis[index] = { ...this.epiEmEdicao };
      this.toast.success('EPI atualizado com sucesso!');
      this.auditService.registrarAcao('Marcio Coelho', 'EPIs', 'EDICAO', `Editou dados do EPI ${this.epiEmEdicao.descricao}`);
    }
    this.fecharModalEdicao();
  }

  filtrarApenasNumerosCa(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input) {
      input.value = input.value.replace(/[^0-9]/g, '').slice(0, 10);
      this.epiEmEdicao.ca = input.value;
    }
  }

  
  
  
  mostrarModalEntrega = false;
  novaEntrega = { colaborador: '', epiId: '', data: '', quantidade: 1 };

  abrirModalEntrega() {
    this.novaEntrega = { colaborador: '', epiId: '', data: new Date().toISOString().split('T')[0], quantidade: 1 };
    this.mostrarModalEntrega = true;
  }

  fecharModalEntrega() {
    this.mostrarModalEntrega = false;
  }

  salvarEntrega() {
    const epiIndex = this.epis.findIndex(e => e.id === this.novaEntrega.epiId);
    
    if (epiIndex === -1) {
      this.toast.error('Selecione um EPI válido.');
      return;
    }

    const epiSelecionado = this.epis[epiIndex];

    if (epiSelecionado.quantidade < this.novaEntrega.quantidade) {
      this.toast.warning('Estoque insuficiente para esta entrega.');
      return;
    }

    
    this.epis[epiIndex].quantidade -= this.novaEntrega.quantidade;

    
    const dataFormatada = this.novaEntrega.data.split('-').reverse().join('/');

    
    this.entregas.unshift({
      colaborador: this.novaEntrega.colaborador,
      epi: epiSelecionado.descricao,
      quantidade: this.novaEntrega.quantidade,
      validadeCa: epiSelecionado.validade,
      numeroCa: epiSelecionado.ca,
      data: dataFormatada,
      assinatura: 'Pendente (Sistema)'
    });

    this.toast.success('Entrega registrada com abatimento no estoque!');
    this.auditService.registrarAcao('Marcio Coelho', 'EPIs', 'CRIACAO', `Registrou entrega de ${this.novaEntrega.quantidade}x ${epiSelecionado.descricao} para ${this.novaEntrega.colaborador}`);
    
    this.fecharModalEntrega();
  }

  
  
  
  get episFiltrados(): Epi[] {
    if (!this.termoBusca) return this.epis;
    const termo = this.termoBusca.toLowerCase();
    return this.epis.filter(e => 
      e.descricao.toLowerCase().includes(termo) || 
      e.id.toLowerCase().includes(termo) ||
      e.ca.includes(termo)
    );
  }

  actionNovoEPI(): void {
    this.router.navigate(['/cadastramentos'], { queryParams: { aba: 'epi' } });
  }
}
