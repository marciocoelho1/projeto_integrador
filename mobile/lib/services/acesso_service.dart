import '../models/acesso.dart';
import 'auth_service.dart';

/// Porta de `src/app/service/acesso.service.ts` (usuários, grupos e módulos).
class AcessoService {
  AcessoService(this._auth);

  final AuthService _auth;
  static const _usuarios = '/usuarios';
  static const _grupos = '/grupos';

  Future<List<UsuarioApi>> listarUsuarios() async {
    final json = await _auth.api.get(_usuarios) as List;
    return json.map((e) => UsuarioApi.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UsuarioApi> criarUsuario(Map<String, dynamic> dados) async {
    final json = await _auth.api.post(_usuarios, dados) as Map<String, dynamic>;
    return UsuarioApi.fromJson(json);
  }

  Future<UsuarioApi> atualizarUsuario(int id, Map<String, dynamic> dados) async {
    final json = await _auth.api.put('$_usuarios/$id', dados) as Map<String, dynamic>;
    return UsuarioApi.fromJson(json);
  }

  Future<void> alterarSenha(int id, String senha) =>
      _auth.api.put('$_usuarios/$id/senha', {'senha': senha});

  Future<void> excluirUsuario(int id) => _auth.api.delete('$_usuarios/$id');

  Future<List<GrupoApi>> listarGrupos() async {
    final json = await _auth.api.get(_grupos) as List;
    return json.map((e) => GrupoApi.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// O back-end usa só o campo `modulos` nesta rota.
  Future<GrupoApi> definirModulos(int id, List<String> modulos) async {
    final json = await _auth.api.put('$_grupos/$id/modulos', {'modulos': modulos})
        as Map<String, dynamic>;
    return GrupoApi.fromJson(json);
  }

  Future<List<ModuloApi>> listarModulos() async {
    final json = await _auth.api.get('/modulos') as List;
    return json.map((e) => ModuloApi.fromJson(e as Map<String, dynamic>)).toList();
  }
}
