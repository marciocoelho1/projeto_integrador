import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ToastService } from '../service/toast.service';
import { AuditService } from '../service/audit.service';
import * as XLSX from 'xlsx'; 

@Component({
  selector: 'app-importacao-massa',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './importacao-massa.html',
  styleUrls: ['./importacao-massa.scss']
})
export class ImportacaoMassa {
  private toast = inject(ToastService);
  private audit = inject(AuditService);

  tipoImportacao = signal<string>('');
  cabecalhos = signal<string[]>([]);
  linhasPreview = signal<string[][]>([]);
  arquivoNome = signal<string>('');

  baixarTemplate() {
    const tipo = this.tipoImportacao();
    if (!tipo) {
      this.toast.warning('Selecione o tipo de importação.');
      return;
    }

    let csvContent = '';
    let nomeArquivo = '';

    switch (tipo) {
      case 'colaborador':
        csvContent = "Nome,CPF,Cargo,Setor\nJoão da Silva,111.222.333-44,Operador de Caixa,Frente de Loja\n";
        nomeArquivo = 'template_colaboradores.csv';
        break;
      case 'treinamento':
        csvContent = "Nome_Treinamento,Carga_Horaria,Validade_Meses,NR_Referente,Obrigatorio\nNR-35 Trabalho em Altura,8,24,NR-35,Sim\n";
        nomeArquivo = 'template_treinamentos.csv';
        break;
      case 'epi':
        csvContent = "Nome_Equipamento,Numero_CA,Fabricante,Validade_Dias,Setor_Risco\nCapacete de Segurança,12345,Delta Plus,365,Estoque\n";
        nomeArquivo = 'template_epis.csv';
        break;
      default:
        return;
    }

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    
    link.setAttribute('href', url);
    link.setAttribute('download', nomeArquivo);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    this.toast.success('Planilha de exemplo baixada com sucesso!');
  }

  onFileChange(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];
    this.arquivoNome.set(file.name);

    const reader = new FileReader();

    
    reader.onload = (e: any) => {
      try {
        const bstr: string = e.target.result;
        const workbook: XLSX.WorkBook = XLSX.read(bstr, { type: 'binary' });

        
        const primeiraAbaNome = workbook.SheetNames[0];
        const worksheet: XLSX.WorkSheet = workbook.Sheets[primeiraAbaNome];

        
        const dadosMatriz = XLSX.utils.sheet_to_json<string[]>(worksheet, { header: 1 });

        if (dadosMatriz && dadosMatriz.length > 0) {
          
          const cabecalhoOriginal = (dadosMatriz[0] as any[]).map(c => String(c || ''));
          this.cabecalhos.set(cabecalhoOriginal);

          
          const linhasDados = dadosMatriz.slice(1).map((row: any[]) => 
            row.map(cell => String(cell !== undefined && cell !== null ? cell : ''))
          ).filter(row => row.some(cell => cell.trim() !== '')); 

          this.linhasPreview.set(linhasDados);
          this.toast.success('Planilha carregada com sucesso! Revise os dados.');
        }
      } catch (error) {
        console.error(error);
        this.toast.error('Erro ao ler o arquivo. Certifique-se de que é uma planilha válida.');
      }
    };

    reader.readAsBinaryString(file);
  }

  confirmarImportacao() {
    const qtd = this.linhasPreview().length;
    
    if (qtd === 0) {
      this.toast.warning('Nenhum dado encontrado para importar.');
      return;
    }

    this.toast.success(`${qtd} registros importados com sucesso!`);
    this.audit.registrarAcao('Marcio Coelho', 'Importação', 'CRIACAO', `Importou ${qtd} registros via planilha Excel/CSV`);
    
    
    this.cabecalhos.set([]);
    this.linhasPreview.set([]);
    this.arquivoNome.set('');
  }
}
