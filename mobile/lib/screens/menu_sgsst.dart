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

  /// Monta a tela. [aoNavegar] permite que os links internos ("Ver todos",
  /// "Repor", "Ver log") levem para outra tela da casca autenticada.
  final Widget Function(AuthService auth, {void Function(String destino)? aoNavegar})
      construir;
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
Widget _dashboard(AuthService auth, {void Function(String)? aoNavegar}) =>
    DashboardScreen(auth: auth, aoNavegar: aoNavegar);
Widget _matriz(AuthService auth, {void Function(String)? aoNavegar}) =>
    MatrizTreinamentoScreen(auth: auth);
Widget _epis(AuthService auth, {void Function(String)? aoNavegar}) =>
    EpisScreen(auth: auth);
Widget _colaboradores(AuthService auth, {void Function(String)? aoNavegar}) =>
    ColaboradoresScreen(auth: auth);
Widget _cadastramentos(AuthService auth, {void Function(String)? aoNavegar}) =>
    CadastramentosScreen(auth: auth);
Widget _importacao(AuthService auth, {void Function(String)? aoNavegar}) =>
    ImportacaoMassaScreen(auth: auth);
Widget _ajudaSuporte(AuthService auth, {void Function(String)? aoNavegar}) =>
    AjudaSuporteScreen(auth: auth);
Widget _configuracoes(AuthService auth, {void Function(String)? aoNavegar}) =>
    ConfiguracoesScreen(auth: auth);
Widget _areaColaborador(AuthService auth, {void Function(String)? aoNavegar}) =>
    AreaColaboradorScreen(auth: auth);
Widget _ajudaColaborador(AuthService auth, {void Function(String)? aoNavegar}) =>
    AjudaSuporteColaboradorScreen(auth: auth);
