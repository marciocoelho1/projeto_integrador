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

/// Os destinos que a barra inferior mostra, na ordem em que aparecem.
///
/// A barra so tem espaco para quatro: os demais ficam no seletor "Todas as
/// telas" e no menu lateral.
List<String> atalhosDoPerfil(AuthService auth) => auth.ehAdmin
    ? const ['Dashboard', 'Colaboradores', 'EPIs', 'Configurações']
    : const ['Área do Colaborador', 'Ajuda e Suporte'];

/// Os itens do perfil que a barra inferior exibe, na ordem dos atalhos.
List<ItemMenuSgsst> itensDaBarra(AuthService auth) {
  final todos = menuDoPerfil(auth);
  return atalhosDoPerfil(auth)
      .map((titulo) => todos.where((i) => i.titulo == titulo).firstOrNull)
      .whereType<ItemMenuSgsst>()
      .toList();
}

/// Subtitulo de cada tela, como no web. O cabecalho da casca mostra o par
/// titulo/subtitulo uma unica vez; as telas nao desenham barra propria quando
/// aparecem dentro dela.
String? subtituloDaTela(String titulo) => switch (titulo) {
      'Dashboard' => 'Indicadores de SST',
      'Colaboradores' => 'Equipe e Matriz de SST',
      'EPIs' => 'Estoque e entregas',
      'Configurações' => 'Acessos, parâmetros e auditoria',
      'Matriz de Treinamentos' => 'LNT, certificações e reciclagens',
      'Cadastramentos' => 'Novo registro',
      'Importação em Massa' => 'Planilha CSV (Excel exportado em CSV)',
      'Ajuda e Suporte' => 'Chamados de ajuda e erros',
      'Área do Colaborador' => null,
      _ => null,
    };

/// As telas do perfil que NAO cabem na barra inferior.
List<ItemMenuSgsst> itensForaDaBarra(AuthService auth) {
  final barra = itensDaBarra(auth);
  return menuDoPerfil(auth)
      .where((i) => !barra.any((b) => b.titulo == i.titulo))
      .toList();
}

// Construtores das telas (referências de função constantes).
Widget _dashboard(AuthService auth, {void Function(String)? aoNavegar}) =>
    DashboardScreen(auth: auth, aoNavegar: aoNavegar);
Widget _matriz(AuthService auth, {void Function(String)? aoNavegar}) =>
    MatrizTreinamentoScreen(auth: auth);
Widget _epis(AuthService auth, {void Function(String)? aoNavegar}) =>
    EpisScreen(auth: auth, aoNavegar: aoNavegar);
Widget _colaboradores(AuthService auth, {void Function(String)? aoNavegar}) =>
    ColaboradoresScreen(auth: auth, aoNavegar: aoNavegar);
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
