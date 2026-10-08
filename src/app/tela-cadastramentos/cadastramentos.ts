import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { ToastService } from '../service/toast.service';
import { AuditService } from '../service/audit.service';
import { DadosReferenciaService } from '../service/dados-referencia.service';

interface NovoColaborador {
  nome: string;
  cpf: string;
  email: string;
  cargo: string;
  setor: string;
  grupoAcessoId: string;
}

@Component({
  selector: 'app-cadastramentos',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './cadastramentos.html',
  styleUrls: ['./cadastramentos.scss'],
})
export class Cadastramentos implements OnInit {
  private route = inject(ActivatedRoute);
  private toast = inject(ToastService);
  private auditService = inject(AuditService);
  private dadosReferencia = inject(DadosReferenciaService);

  readonly cargosCadastrados = this.dadosReferencia.cargosCadastrados;
  readonly setoresCadastrados = this.dadosReferencia.setoresCadastrados;
  readonly gruposAcesso = this.dadosReferencia.gruposAcesso;
  novoColaborador: NovoColaborador = {
    nome: '',
    cpf: '',
    email: '',
    cargo: '',
    setor: '',
    grupoAcessoId: '',
  };

  abaAtual: 'colaborador' | 'treinamento' | 'epi' | 'lnt' | 'reciclagem' = 'colaborador';

  ngOnInit(): void {
    this.route.queryParams.subscribe((params) => {
      if (params['aba']) {
        this.abaAtual = params['aba'] as
          'colaborador' | 'treinamento' | 'epi' | 'lnt' | 'reciclagem';
      }
    });
  }

  salvarColaborador(formulario: NgForm): void {
    const emailValido = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.novoColaborador.email.trim());

    if (formulario.invalid || !emailValido) {
      formulario.control.markAllAsTouched();
      const mensagem =
        formulario.controls['email']?.invalid || !emailValido
          ? 'Informe um e-mail corporativo válido.'
          : 'Preencha todos os campos obrigatórios.';
      this.toast.error(mensagem);
      return;
    }

    console.log('Colaborador salvo!');
    this.toast.success('Colaborador cadastrado com sucesso!');

    this.auditService.registrarAcao(
      'Marcio Coelho',
      'Cadastramentos',
      'CRIACAO',
      'Cadastrou novo colaborador',
    );
  }

  salvarTreinamento() {
    console.log('Treinamento salvo!');
    this.toast.success('Novo Treinamento adicionado com sucesso!');

    this.auditService.registrarAcao(
      'Marcio Coelho',
      'Cadastramentos',
      'CRIACAO',
      'Cadastrou novo treinamento',
    );
  }

  salvarEPI() {
    console.log('EPI salvo!');
    this.toast.success('Novo EPI adicionado com sucesso!');

    this.auditService.registrarAcao(
      'Marcio Coelho',
      'Cadastramentos',
      'CRIACAO',
      'Cadastrou novo EPI no estoque',
    );
  }

  salvarLnt() {
    console.log('LNT / Cargo salvo!');
    this.toast.success('Novo LNT / Cargo salvo com sucesso!');
    this.auditService.registrarAcao(
      'Marcio Coelho',
      'Cadastramentos',
      'CRIACAO',
      'Cadastrou novo LNT / Cargo',
    );
  }

  salvarReciclagem() {
    console.log('Reciclagem salva!');
    this.toast.success('Nova Reciclagem cadastrada com sucesso!');
    this.auditService.registrarAcao(
      'Marcio Coelho',
      'Cadastramentos',
      'CRIACAO',
      'Cadastrou nova reciclagem',
    );
  }
}
