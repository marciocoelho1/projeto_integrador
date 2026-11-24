import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Limite de estoque do card "EPIs em estoque critico" (mesmo ESTOQUE_MINIMO do web).
const int kEstoqueMinimo = 5;

/// Quantos itens cabem nas listas curtas do painel (LIMITE_LISTA do web).
const int kLimiteLista = 5;

const List<String> _mesesCurtos = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
];

/// Cabecalho padrao dos cards do painel: titulo, subtitulo e um link de acao.
class CabecalhoBloco extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String? acao;
  final VoidCallback? aoAcionar;
  final Widget? extra;

  const CabecalhoBloco({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.acao,
    this.aoAcionar,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700, color: AppCores.tinta)),
              const SizedBox(height: 2),
              Text(subtitulo,
                  style: const TextStyle(fontSize: 12, color: AppCores.cinza)),
            ],
          ),
        ),
        ?extra,
        if (acao != null)
          TextButton(
            onPressed: aoAcionar,
            style: TextButton.styleFrom(
              foregroundColor: AppCores.petroleo,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(acao!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

/// Etiqueta curta com cor, equivalente ao chip--{cor} do web.
class ChipSituacao extends StatelessWidget {
  final String texto;
  final Color cor;

  const ChipSituacao({super.key, required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(texto,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cor)),
    );
  }
}

/// Bloco "Colaboradores por setor": barras horizontais proporcionais.
class BlocoSetores extends StatelessWidget {
  final List<({String setor, int total})> setores;
  final VoidCallback? aoVerTodos;

  const BlocoSetores({super.key, required this.setores, this.aoVerTodos});

  @override
  Widget build(BuildContext context) {
    final maior = setores.fold<int>(0, (maximo, s) => s.total > maximo ? s.total : maximo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoracaoCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoBloco(
            titulo: 'Colaboradores por setor',
            subtitulo: 'Onde está o quadro',
            acao: 'Ver todos',
            aoAcionar: aoVerTodos,
          ),
          const SizedBox(height: 12),
          if (setores.isEmpty)
            const TextoVazio('Nenhum colaborador cadastrado.')
          else
            ...setores.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(s.setor,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: AppCores.cinza)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: maior > 0 ? s.total / maior : 0,
                            minHeight: 8,
                            backgroundColor: AppCores.areia,
                            valueColor: const AlwaysStoppedAnimation(AppCores.petroleo),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 26,
                        child: Text('${s.total}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700, color: AppCores.tinta)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

/// Bloco "Pendencias por NR e setor": matriz calor com legenda.
class BlocoMatrizCalor extends StatelessWidget {
  final List<String> nrs;
  final List<({String setor, List<int> valores, int total})> linhas;
  final List<int> totaisPorNr;
  final int total;
  final int janelaAlertaDias;

  const BlocoMatrizCalor({
    super.key,
    required this.nrs,
    required this.linhas,
    required this.totaisPorNr,
    required this.total,
    this.janelaAlertaDias = 30,
  });

  static const List<Color> cores = [
    Color(0xFFBBF7D0), // 0 - em dia
    Color(0xFFFDE68A), // 1 - uma pendencia
    Color(0xFFFEE2E2), // 2 ou mais
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoracaoCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoBloco(
            titulo: 'Pendências por NR e setor',
            subtitulo: 'Vínculos vencidos ou a vencer em $janelaAlertaDias dias',
            extra: total > 0
                ? ChipSituacao(
                    texto: '$total ${total == 1 ? 'pendência' : 'pendências'}',
                    cor: AppCores.vencido)
                : const ChipSituacao(texto: 'Sem pendências', cor: AppCores.valido),
          ),
          const SizedBox(height: 12),
          if (nrs.isEmpty)
            const TextoVazio('Nenhum vínculo com NR registrado até agora.')
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(52),
                border: TableBorder.all(color: AppCores.hairline, width: 1),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppCores.areia),
                    children: [
                      const CelulaCabecalho('Setor', largura: 104, alinharEsquerda: true),
                      ...nrs.map((nr) => CelulaCabecalho(nr)),
                      const CelulaCabecalho('Total'),
                    ],
                  ),
                  ...linhas.map((linha) => TableRow(
                        children: [
                          CelulaCabecalho(linha.setor, largura: 104, alinharEsquerda: true),
                          ...List.generate(nrs.length, (i) {
                            final valor = linha.valores[i];
                            return Container(
                              height: 32,
                              alignment: Alignment.center,
                              color: cores[valor == 0 ? 0 : (valor == 1 ? 1 : 2)],
                              child: Text('$valor',
                                  style: const TextStyle(fontSize: 12, color: AppCores.tinta)),
                            );
                          }),
                          CelulaCabecalho('${linha.total}'),
                        ],
                      )),
                  TableRow(
                    children: [
                      const CelulaCabecalho('Total', largura: 104, alinharEsquerda: true),
                      ...totaisPorNr.map((t) => CelulaCabecalho('$t')),
                      CelulaCabecalho('$total'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                LegendaCor(cor: cores[0], texto: '0 em dia'),
                LegendaCor(cor: cores[1], texto: '1 pendência'),
                LegendaCor(cor: cores[2], texto: '2 ou mais'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CelulaCabecalho extends StatelessWidget {
  final String texto;
  final double? largura;
  final bool alinharEsquerda;

  const CelulaCabecalho(this.texto, {super.key, this.largura, this.alinharEsquerda = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largura,
      height: 32,
      alignment: alinharEsquerda ? Alignment.centerLeft : Alignment.center,
      padding: alinharEsquerda ? const EdgeInsets.only(left: 8) : EdgeInsets.zero,
      child: Text(texto,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppCores.cinza)),
    );
  }
}

class LegendaCor extends StatelessWidget {
  final Color cor;
  final String texto;

  const LegendaCor({super.key, required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(texto, style: const TextStyle(fontSize: 11.5, color: AppCores.cinza)),
      ],
    );
  }
}

/// Bloco "EPIs em estoque critico".
class BlocoEpisCriticos extends StatelessWidget {
  final List<({String descricao, String ca, int quantidade, String situacao, Color cor})> itens;
  final int restantes;
  final int estoqueMinimo;
  final VoidCallback? aoRepor;

  const BlocoEpisCriticos({
    super.key,
    required this.itens,
    required this.restantes,
    this.estoqueMinimo = kEstoqueMinimo,
    this.aoRepor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoracaoCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoBloco(
            titulo: 'EPIs em estoque crítico',
            subtitulo: 'No limite ou abaixo do mínimo de $estoqueMinimo un.',
            acao: 'Repor',
            aoAcionar: aoRepor,
          ),
          const SizedBox(height: 8),
          if (itens.isEmpty)
            const TextoVazio('Nenhum EPI no nível crítico.')
          else
            ...itens.map((epi) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(epi.descricao,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppCores.tinta)),
                            Text('CA ${epi.ca} - ${epi.quantidade} un.',
                                style: const TextStyle(fontSize: 11.5, color: AppCores.cinza)),
                          ],
                        ),
                      ),
                      ChipSituacao(texto: epi.situacao, cor: epi.cor),
                    ],
                  ),
                )),
          if (restantes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('+ $restantes tipo(s) em nível crítico',
                  style: const TextStyle(fontSize: 11.5, color: AppCores.cinza)),
            ),
        ],
      ),
    );
  }
}

/// Bloco "Entregas de EPI": barras verticais dos ultimos 6 meses.
class BlocoEntregasMes extends StatelessWidget {
  final int total;
  final List<({String rotulo, int valor})> meses;
  final VoidCallback? aoVerEntregas;

  const BlocoEntregasMes({
    super.key,
    required this.total,
    required this.meses,
    this.aoVerEntregas,
  });

  @override
  Widget build(BuildContext context) {
    final maior = meses.fold<int>(0, (maximo, m) => m.valor > maximo ? m.valor : maximo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoracaoCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoBloco(
            titulo: 'Entregas de EPI',
            subtitulo: '$total unidade(s) nos últimos 6 meses',
            acao: 'Ver entregas',
            aoAcionar: aoVerEntregas,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: meses.map((mes) {
                final altura = maior > 0 ? (mes.valor / maior) * 88 : 4.0;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${mes.valor}',
                          style: const TextStyle(fontSize: 11, color: AppCores.cinza)),
                      const SizedBox(height: 3),
                      Container(
                        height: altura < 4 ? 4 : altura,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: const BoxDecoration(
                          color: AppCores.petroleo,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(mes.rotulo,
                          style: const TextStyle(fontSize: 10.5, color: AppCores.cinza)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloco "Ultimas entregas": termos de entrega mais recentes.
class BlocoUltimasEntregas extends StatelessWidget {
  final List<({String colaborador, String epi, int quantidade, String data, bool assinado})> itens;
  final VoidCallback? aoVerTodas;

  const BlocoUltimasEntregas({super.key, required this.itens, this.aoVerTodas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoracaoCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoBloco(
            titulo: 'Últimas entregas',
            subtitulo: 'Últimos termos de entrega registrados',
            acao: 'Ver todas',
            aoAcionar: aoVerTodas,
          ),
          const SizedBox(height: 8),
          if (itens.isEmpty)
            const TextoVazio('Nenhuma entrega de EPI registrada.')
          else
            ...itens.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.colaborador,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppCores.tinta)),
                            Text('${e.epi} - ${e.quantidade} un. - ${e.data}',
                                style: const TextStyle(fontSize: 11.5, color: AppCores.cinza)),
                          ],
                        ),
                      ),
                      ChipSituacao(
                        texto: e.assinado ? 'Assinado' : 'Sem assinatura',
                        cor: e.assinado ? AppCores.valido : AppCores.vencendo,
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

/// Bloco "Atividade recente": ultimos eventos da trilha de auditoria.
class BlocoAtividadeRecente extends StatelessWidget {
  final List<({String descricao, String quando, Color cor})> eventos;
  final VoidCallback? aoVerLog;

  const BlocoAtividadeRecente({super.key, required this.eventos, this.aoVerLog});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoracaoCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoBloco(
            titulo: 'Atividade recente',
            subtitulo: 'Últimos eventos de auditoria',
            acao: 'Ver log',
            aoAcionar: aoVerLog,
          ),
          const SizedBox(height: 8),
          if (eventos.isEmpty)
            const TextoVazio('Nenhum evento de auditoria registrado.')
          else
            ...eventos.map((evento) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5, right: 9),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: evento.cor, shape: BoxShape.circle),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(evento.descricao,
                                style: const TextStyle(fontSize: 13, color: AppCores.tinta)),
                            Text(evento.quando,
                                style: const TextStyle(fontSize: 11, color: AppCores.cinza)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

/// Texto padrao das listas vazias.
class TextoVazio extends StatelessWidget {
  final String texto;
  const TextoVazio(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(texto, style: const TextStyle(fontSize: 12.5, color: AppCores.cinza)),
      );
}

/// Decoracao padrao dos cards do painel.
BoxDecoration decoracaoCard() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppCores.hairline),
    );

/// Rotulo curto do mes (1-12), igual ao MESES_CURTOS do web.
String mesCurto(int mes) => _mesesCurtos[mes - 1];

/// Cor da bolinha da atividade conforme a acao registrada na auditoria.
Color corDoLog(String acao) {
  final normalizada = acao.toUpperCase();
  if (normalizada.contains('EXCLU') || normalizada.contains('ERRO')) return AppCores.vencido;
  if (normalizada.contains('CRI') || normalizada.contains('CADASTR')) return AppCores.valido;
  if (normalizada.contains('ATUALIZ') || normalizada.contains('EDIT')) return AppCores.petroleo;
  return AppCores.cinza;
}
