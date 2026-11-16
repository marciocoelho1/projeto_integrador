import { ChangeDetectionStrategy, Component, OnInit, computed, effect, inject, signal } from '@angular/core';
import { CommonModule, TitleCasePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuditService } from '../service/audit.service';
import { type ChaveModulo } from '../service/dados-referencia.service';
import { AcessoService, type UsuarioApi } from '../service/acesso.service';
import { ToastService } from '../service/toast.service';
import { AuthService } from '../auth.service';
import { mensagemErroApi } from '../service/api-error';
import {
  ConfiguracoesGlobaisService,
  type ParametroSistema,
} from '../service/configuracoes-globais.service';

const ROTAS_SISTEMA = {
  novoUsuario: '/cadastramentos/novo-usuario',
  detalhesUsuario: (id: string) => `/cadastramentos/usuario/${id}`,
  editarUsuario: (id: string) => `/cadastramentos/editar-usuario/${id}`,
  resetarSenha: (id: string) => `/cadastramentos/usuario/${id}/senha`,
  matrizAcesso: (id: string) => `/cadastramentos/usuario/${id}/acessos`,
} as const;

type StatusUsuario = 'ativo' | 'inativo';

interface UsuarioSst {
  id: string;
  login: string;
  nomeCompleto: string;
  emailCorporativo: string;
  cpf: string;
  grupoId: string;
  status: StatusUsuario;
  senha?: string;
}

interface GrupoSst {
  id: string;
  nomenclatura: string;
  finalidade: string;
  modulosLiberados: ChaveModulo[];
}

interface ModuloSistema {
  chave: ChaveModulo;
  titulo: string;
  detalhe: string;
}

type GuiaConfiguracao = 'usuarios' | 'grupos' | 'matriz' | 'globais' | 'logs';

@Component({
  selector: 'app-configuracoes',
  standalone: true,
  imports: [CommonModule, FormsModule, TitleCasePipe],
  templateUrl: './configuracoes.html',
  styleUrl: './configuracoes.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Configuracoes implements OnInit {
  private readonly router = inject(Router);
  private readonly toastService = inject(ToastService);
  private readonly auditService = inject(AuditService);
  private readonly acesso = inject(AcessoService);
  private readonly auth = inject(AuthService);
  private readonly globais = inject(ConfiguracoesGlobaisService);

  protected readonly rotas = ROTAS_SISTEMA;

  protected mostrarModalEdicaoUsuario = signal<boolean>(false);
  protected usuarioEmEdicao = signal<UsuarioSst | null>(null);
  protected modoNovoUsuario = signal<boolean>(false);
  protected salvandoUsuario = signal<boolean>(false);
  protected carregandoAcessos = signal<boolean>(false);

  protected readonly guiasNavegacao: { id: GuiaConfiguracao; titulo: string }[] = [
    { id: 'usuarios', titulo: 'Usuários do Sistema' },
    { id: 'grupos', titulo: 'Grupos de Usuários' },
    { id: 'matriz', titulo: 'Matriz de Acessos' },
    { id: 'globais', titulo: 'Configurações Globais' },
    { id: 'logs', titulo: 'Logs de Auditoria' },
  ];

  protected readonly guiaAtual = signal<GuiaConfiguracao>('usuarios');

  /** Carregado de GET /api/modulos. */
  protected modulosDisponiveis: ModuloSistema[] = [];

  /** Carregado de GET /api/grupos. */
  protected readonly gruposSst = signal<GrupoSst[]>([]);

  protected filtroLogTermo = signal('');
  protected filtroLogDataInicio = signal('');
  protected filtroLogDataFim = signal('');

  /** Os logs vêm de GET /api/auditoria (o servidor já aplica termo e intervalo de datas). */
  protected readonly logsFiltrados = computed(() => this.auditService.logs());

  /** Carregado de GET /api/usuarios. */
  protected readonly usuariosCadastrados = signal<UsuarioSst[]>([]);

  protected readonly termoBusca = signal('');

  protected readonly usuariosFiltrados = computed(() => {
    const termo = this.termoBusca().trim().toLowerCase();
    if (!termo) return this.usuariosCadastrados();

    return this.usuariosCadastrados().filter((usuario) => {
      const nome = usuario.nomeCompleto.toLowerCase();
      const cpfMatricula = usuario.cpf.toLowerCase();
      const status = usuario.status.toLowerCase();
      const grupoNome = this.getNomeGrupo(usuario.grupoId).toLowerCase();

      return (
        nome.includes(termo) ||
        cpfMatricula.includes(termo) ||
        status.includes(termo) ||
        grupoNome.includes(termo)
      );
    });
  });

  protected readonly grupoSelecionadoId = signal<string>('');

  protected readonly grupoEmEdicao = computed(
    () => this.gruposSst().find((g) => g.id === this.grupoSelecionadoId()) ?? this.gruposSst()[0],
  );

  /** Regras de alerta persistidas (GET /api/regras-alerta). */
  protected readonly regrasAlertas = this.globais.regras;

  /** Parâmetros globais de GET /api/parametros, em cópia editável enquanto a tela está aberta. */
  protected readonly parametrosEmEdicao = signal<ParametroSistema[]>([]);

  protected readonly erroGlobais = this.globais.erro;
  protected readonly carregandoGlobais = this.globais.carregando;
  protected readonly salvandoGlobais = this.globais.salvando;

  constructor() {
    // Carrega os logs da API ao abrir a guia e recarrega quando um filtro muda.
    effect(() => {
      if (this.guiaAtual() !== 'logs') {
        return;
      }

      this.auditService.carregar({
        termo: this.filtroLogTermo(),
        inicio: this.filtroLogDataInicio(),
        fim: this.filtroLogDataFim(),
      });
    });

    // A cópia editável dos parâmetros acompanha o que veio da API (na carga e a cada gravação).
    effect(() => {
      const parametros = this.globais.parametros();

      if (parametros.length > 0) {
        this.parametrosEmEdicao.set(parametros.map((parametro) => ({ ...parametro })));
      }
    });
  }

  ngOnInit(): void {
    this.carregarModulos();
    this.carregarGrupos();
    this.carregarUsuarios();
    this.globais.carregar();
  }

  protected navegarGuia(guia: GuiaConfiguracao): void {
    this.guiaAtual.set(guia);
  }

  protected getNomeGrupo(grupoId: string): string {
    return this.gruposSst().find((g) => g.id === grupoId)?.nomenclatura || 'Indefinido';
  }

  protected irParaMatrizDoGrupo(grupoId: string): void {
    this.grupoSelecionadoId.set(grupoId);
    this.guiaAtual.set('matriz');
  }

  /** Recalcula a matriz do grupo na API (PUT /api/grupos/{id}/modulos). */
  protected alternarAcessoModulo(chave: ChaveModulo): void {
    const grupo = this.grupoEmEdicao();

    if (!grupo) {
      return;
    }

    const modulos = grupo.modulosLiberados.includes(chave)
      ? grupo.modulosLiberados.filter((c) => c !== chave)
      : [...grupo.modulosLiberados, chave];

    this.gruposSst.update((lista) =>
      lista.map((g) => (g.id === grupo.id ? { ...g, modulosLiberados: modulos } : g)),
    );

    this.acesso.definirModulos(Number(grupo.id), modulos).subscribe({
      next: (resposta) =>
        this.gruposSst.update((lista) =>
          lista.map((g) =>
            g.id === grupo.id
              ? { ...g, modulosLiberados: resposta.modulos as ChaveModulo[] }
              : g,
          ),
        ),
      error: (erro) => {
        this.toastService.error(mensagemErroApi(erro));
        this.carregarGrupos();
      },
    });
  }

  /** Liga/desliga a regra na tela e grava em PUT /api/regras-alerta/{codigo}. */
  protected alternarRegra(codigo: string): void {
    const regra = this.regrasAlertas().find((atual) => atual.codigo === codigo);

    if (!regra) {
      return;
    }

    const isAtiva = !regra.isAtiva;

    this.regrasAlertas.update((lista) =>
      lista.map((atual) => (atual.codigo === codigo ? { ...atual, isAtiva } : atual)),
    );

    this.globais.definirAtiva(codigo, isAtiva).subscribe({
      error: (erro) => {
        this.toastService.error(mensagemErroApi(erro));
        this.globais.carregar();
      },
    });
  }

  protected alterarParametro(chave: string, valor: string): void {
    this.parametrosEmEdicao.update((lista) =>
      lista.map((parametro) => (parametro.chave === chave ? { ...parametro, valor } : parametro)),
    );
  }

  /**
   * Grava em PUT /api/parametros/{chave} só o que mudou em relação ao valor que veio do servidor,
   * para o botão "Salvar Configurações" não regravar tudo a cada clique.
   */
  protected gravarAlteracoesGlobais(): void {
    const originais = this.globais.parametros();
    const alterados = this.parametrosEmEdicao().filter(
      (parametro) =>
        parametro.valor !==
        (originais.find((original) => original.chave === parametro.chave)?.valor ?? ''),
    );

    if (alterados.length === 0) {
      this.toastService.warning('Nenhuma alteração de parâmetro para salvar.');
      return;
    }

    this.globais.salvarValores(alterados).subscribe({
      next: () => this.toastService.success('Parâmetros atualizados.'),
      error: (erro) => this.toastService.error(mensagemErroApi(erro)),
    });
  }

  actionNovoUsuario(): void {
    this.modoNovoUsuario.set(true);
    this.usuarioEmEdicao.set({
      id: '',
      login: '',
      nomeCompleto: '',
      emailCorporativo: '',
      cpf: '',
      grupoId: this.gruposSst()[0]?.id ?? '',
      status: 'ativo',
      senha: '',
    });
    this.mostrarModalEdicaoUsuario.set(true);
  }

  protected actionEditarUsuario(usuario: UsuarioSst): void {
    this.modoNovoUsuario.set(false);
    this.usuarioEmEdicao.set({ ...usuario, senha: '' });
    this.mostrarModalEdicaoUsuario.set(true);
  }

  protected fecharModalEdicaoUsuario(): void {
    this.mostrarModalEdicaoUsuario.set(false);
    this.modoNovoUsuario.set(false);
    this.usuarioEmEdicao.set(null);
  }

  protected salvarEdicaoUsuario(): void {
    const usuario = this.usuarioEmEdicao();

    if (!usuario || this.salvandoUsuario()) {
      return;
    }

    const novo = this.modoNovoUsuario();
    const senha = (usuario.senha ?? '').trim();

    if (!usuario.nomeCompleto.trim() || !usuario.login.trim()) {
      this.toastService.error('Informe o nome completo e o usuário de acesso.');
      return;
    }

    if (usuario.cpf.replace(/\D/g, '').length !== 11) {
      this.toastService.error('O CPF deve conter 11 dígitos.');
      return;
    }

    if (novo && (senha.length < 6 || senha.length > 72)) {
      this.toastService.error('Informe uma senha de 6 a 72 caracteres.');
      return;
    }

    if (!novo && senha && (senha.length < 6 || senha.length > 72)) {
      this.toastService.error('A nova senha deve ter de 6 a 72 caracteres.');
      return;
    }

    if (!usuario.grupoId) {
      this.toastService.error('Selecione o grupo de acesso.');
      return;
    }

    const dados = {
      nomeCompleto: usuario.nomeCompleto.trim(),
      login: usuario.login.trim(),
      email: usuario.emailCorporativo.trim(),
      cpf: usuario.cpf,
      grupoId: Number(usuario.grupoId),
      status: (usuario.status === 'ativo' ? 'Ativo' : 'Inativo') as 'Ativo' | 'Inativo',
      ...(senha ? { senha } : {}),
    };

    this.salvandoUsuario.set(true);

    const requisicao = novo
      ? this.acesso.criarUsuario(dados)
      : this.acesso.atualizarUsuario(Number(usuario.id), dados);

    requisicao.subscribe({
      next: (salvo) => {
        this.salvandoUsuario.set(false);
        this.usuariosCadastrados.update((lista) =>
          novo
            ? [...lista, this.paraUsuarioSst(salvo)]
            : lista.map((u) =>
                u.id === String(salvo.id) ? this.paraUsuarioSst(salvo) : u,
              ),
        );
        this.toastService.success(
          novo
            ? `Usuário "${salvo.nomeCompleto}" cadastrado com sucesso!`
            : `Usuário "${salvo.nomeCompleto}" atualizado com sucesso!`,
        );
        this.auditService.registrarAcao(
          this.auth.getCurrentUser()?.nomeExibicao ?? 'Administrador',
          'Configurações',
          novo ? 'CRIACAO' : 'EDICAO',
          `${novo ? 'Cadastrou' : 'Atualizou'} usuário ${salvo.nomeCompleto}`,
        );
        this.fecharModalEdicaoUsuario();
      },
      error: (erro) => {
        this.salvandoUsuario.set(false);
        this.toastService.error(mensagemErroApi(erro));
      },
    });
  }

  private carregarModulos(): void {
    this.acesso.listarModulos().subscribe({
      next: (modulos) =>
        (this.modulosDisponiveis = modulos.map((modulo) => ({
          chave: modulo.chave as ChaveModulo,
          titulo: modulo.titulo,
          detalhe: modulo.detalhe,
        }))),
      error: (erro) => this.toastService.error(mensagemErroApi(erro)),
    });
  }

  private carregarGrupos(): void {
    this.acesso.listarGrupos().subscribe({
      next: (grupos) => {
        const mapeados: GrupoSst[] = grupos.map((grupo) => ({
          id: String(grupo.id),
          nomenclatura: grupo.nomenclatura,
          finalidade: grupo.finalidade,
          modulosLiberados: grupo.modulos as ChaveModulo[],
        }));

        this.gruposSst.set(mapeados);

        if (!this.grupoSelecionadoId() && mapeados.length > 0) {
          this.grupoSelecionadoId.set(mapeados[0].id);
        }
      },
      error: (erro) => this.toastService.error(mensagemErroApi(erro)),
    });
  }

  protected carregarUsuarios(): void {
    this.carregandoAcessos.set(true);

    this.acesso.listarUsuarios().subscribe({
      next: (usuarios) => {
        this.usuariosCadastrados.set(usuarios.map((u) => this.paraUsuarioSst(u)));
        this.carregandoAcessos.set(false);
      },
      error: (erro) => {
        this.carregandoAcessos.set(false);
        this.toastService.error(mensagemErroApi(erro));
      },
    });
  }

  private paraUsuarioSst(usuario: UsuarioApi): UsuarioSst {
    return {
      id: String(usuario.id),
      login: usuario.login,
      nomeCompleto: usuario.nomeCompleto,
      emailCorporativo: usuario.email,
      cpf: usuario.cpf,
      grupoId: String(usuario.grupoId),
      status: usuario.status === 'Ativo' ? 'ativo' : 'inativo',
    };
  }
}
