import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'ajuda_suporte_colaborador_screen.dart';
import 'ajuda_suporte_screen.dart';
import 'area_colaborador_screen.dart';
import 'cadastramentos_screen.dart';
import 'colaboradores_screen.dart';
import 'configuracoes_screen.dart';
import 'dashboard_screen.dart';
import 'epis_screen.dart';
import 'importacao_massa_screen.dart';
import 'matriz_treinamento_screen.dart';

/// Um destino do menu, com o mesmo recorte de perfil do layout web.
class ItemMenuSgsst {
  const ItemMenuSgsst(this.titulo, this.icone, this.construir);

  final String titulo;
  final IconData icone;
  final Widget Function(AuthService auth) construir;
}

/// Menu "administrador": espelha o bloco `userRole === 'admin'` do layout web.
const menuAdministrador = <ItemMenuSgsst>[
  ItemMenuSgsst('Dashboard', Icons.dashboard_outlined, _dashboard),
  ItemMenuSgsst('Matriz de Treinamentos', Icons.school_outlined, _matriz),
  ItemMenuSgsst('EPIs', Icons.shield_outlined, _epis),
  ItemMenuSgsst('Colaboradores', Icons.people_outline, _colaboradores),
  ItemMenuSgsst('Cadastramentos', Icons.app_registration, _cadastramentos),
  ItemMenuSgsst('Importação em Massa', Icons.upload_file_outlined, _importacao),
  ItemMenuSgsst('Ajuda e Suporte', Icons.support_agent, _ajudaSuporte),
  ItemMenuSgsst('Configurações', Icons.settings_outlined, _configuracoes),
];

/// Menu "colaborador": espelha o bloco `userRole === 'colaborador'`.
const menuColaborador = <ItemMenuSgsst>[
  ItemMenuSgsst('Área do Colaborador', Icons.badge_outlined, _areaColaborador),
  ItemMenuSgsst('Ajuda e Suporte', Icons.support_agent, _ajudaColaborador),
];

List<ItemMenuSgsst> menuDoPerfil(AuthService auth) =>
    auth.ehAdmin ? menuAdministrador : menuColaborador;

// Construtores das telas (referências de função constantes).
Widget _dashboard(AuthService auth) => DashboardScreen(auth: auth);
Widget _matriz(AuthService auth) => MatrizTreinamentoScreen(auth: auth);
Widget _epis(AuthService auth) => EpisScreen(auth: auth);
Widget _colaboradores(AuthService auth) => ColaboradoresScreen(auth: auth);
Widget _cadastramentos(AuthService auth) => CadastramentosScreen(auth: auth);
Widget _importacao(AuthService auth) => ImportacaoMassaScreen(auth: auth);
Widget _ajudaSuporte(AuthService auth) => AjudaSuporteScreen(auth: auth);
Widget _configuracoes(AuthService auth) => ConfiguracoesScreen(auth: auth);
Widget _areaColaborador(AuthService auth) => AreaColaboradorScreen(auth: auth);
Widget _ajudaColaborador(AuthService auth) =>
    AjudaSuporteColaboradorScreen(auth: auth);
