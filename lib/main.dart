
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//esto señala la base de datos de laravel, si se cambia la ip o el puerto, se debe cambiar aqui tambien
const String servidorLaravel = 'http://127.0.0.1:8000';

void main() {
  runApp(const ProyecMozo());
}

class ProyecMozo extends StatelessWidget {
  const ProyecMozo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pedidos en Cocina',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const PedidosCocinaScreen(),
    );
  }
}

class Producto {
  final int cantidad;
  final String nombre;
  final String detalle;
  final String observacion;
  final String imagen;

  const Producto({
    required this.cantidad,
    required this.nombre,
    required this.detalle,
    this.observacion = '',
    this.imagen = '',
  });
}

class Pedido {
  final int numero;
  final String mesa;
  final String hora;
  final List<Producto> productos;
  bool preparando;
  bool guardandoEstado;

  Pedido({
    required this.numero,
    required this.mesa,
    required this.hora,
    required this.productos,
    this.preparando = false,
    this.guardandoEstado = false,
  });
}


class PedidosCocinaScreen extends StatefulWidget {
  const PedidosCocinaScreen({super.key});

  @override
  State<PedidosCocinaScreen> createState() =>
      _PedidosCocinaScreenState();
}

class _PedidosCocinaScreenState extends State<PedidosCocinaScreen> {
  static const String apiBaseUrl = servidorLaravel;

  static const Color azulOscuro = Color(0xFF002548);
  static const Color azul = Color(0xFF0870A5);
  static const Color naranja = Color(0xFFE58A24);
  static const Color verde = Color(0xFF26834A);
  

  List<Pedido> pedidos = [];
  final List<Pedido> pedidosAnteriores = [];

  bool cargando = false;
  String? errorCarga;

  @override
  void initState() {
    super.initState();
    cargarPedidos();
  }

  Future<void> cargarPedidos() async {
    if (cargando) return;

    setState(() {
      cargando = true;
      errorCarga = null;
    });

    try {
      final respuesta = await http
          .get(
            Uri.parse('$apiBaseUrl/api/cocina/pedidos'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode < 200 ||
          respuesta.statusCode >= 300) {
        throw Exception(
          'El servidor respondió con el código '
          '${respuesta.statusCode}.',
        );
      }

      final dynamic contenido = jsonDecode(respuesta.body);
      final dynamic listaJson = contenido is List
          ? contenido
          : (contenido is Map ? contenido['data'] : null);

      if (listaJson is! List) {
        throw Exception(
          'La respuesta de la API no contiene una lista de pedidos.',
        );
      }

      final List<Pedido> pedidosNuevos = [];

      for (final dynamic elemento in listaJson) {
        if (elemento is! Map) continue;

        final Map<String, dynamic> pedidoJson =
            Map<String, dynamic>.from(elemento);
            // Los pedidos ya listos no deben volver a la lista de pendientes.
final String estadoPedido =
    (pedidoJson['estado'] ?? '').toString().toLowerCase().trim();
final String idEstado = '${pedidoJson['fk_id_estado'] ?? ''}';

if (idEstado == '3' || estadoPedido == 'listo') continue;

        final dynamic detallesJson =
            pedidoJson['detalles'] ??
            pedidoJson['detalle_pedido'];

        final List<Producto> productos = [];

        if (detallesJson is List) {
          for (final dynamic detalleElemento in detallesJson) {
            if (detalleElemento is! Map) continue;

            final Map<String, dynamic> detalle =
                Map<String, dynamic>.from(detalleElemento);

            final dynamic productoJson = detalle['producto'];

            final Map<String, dynamic> productoDatos =
                productoJson is Map
                    ? Map<String, dynamic>.from(productoJson)
                    : <String, dynamic>{};

            final String nombre = (
              productoDatos['nombre'] ??
              productoDatos['nombre_producto'] ??
              detalle['nombre'] ??
              detalle['producto_nombre'] ??
              'Producto'
            ).toString();

            final int cantidad =
                int.tryParse('${detalle['cantidad'] ?? 1}') ?? 1;

            final String observacion = (
              detalle['descripcion'] ??
              detalle['observacion'] ??
              ''
            ).toString().trim();

            final String ingredientes = (
              productoDatos['ingredientes'] ??
              productoDatos['descripcion'] ??
              detalle['ingredientes'] ??
              ''
            ).toString().trim();

            final String imagen = (
              productoDatos['imagen'] ??
              productoDatos['ruta_imagen'] ??
              productoDatos['foto'] ??
              // La API de cocina devuelve la imagen directamente en el detalle.
              detalle['imagen'] ??
              detalle['ruta_imagen'] ??
              detalle['foto'] ??
              ''
            ).toString().trim();

            productos.add(
              Producto(
                cantidad: cantidad,
                nombre: nombre,
                detalle: ingredientes.isNotEmpty
                    ? ingredientes
                    : 'Sin información .',
                observacion: observacion,
                imagen: imagen,
              ),
            );
          }
        }

        if (productos.isEmpty) continue;

        final int numero = int.tryParse(
              '${pedidoJson['id_pedido'] ?? pedidoJson['id'] ?? 0}',
            ) ??
            0;

        final dynamic mesaJson = pedidoJson['mesa'];

        final dynamic numeroMesa = mesaJson is Map
            ? (mesaJson['numero_mesa'] ??
                mesaJson['id_mesa'] ??
                mesaJson['id'])
            : (pedidoJson['fk_id_mesa'] ?? pedidoJson['mesa']);

        final dynamic llevar = pedidoJson['es_para_llevar'];

        final bool paraLlevar =
            llevar == true || llevar == 1 || llevar == '1';

        final String mesa = paraLlevar
            ? 'Para llevar'
            : 'Mesa ${numeroMesa ?? '-'}';

        final String hora = _formatearHora(
          pedidoJson['hora_pedido'] ??
              pedidoJson['fecha_pedido'] ??
              pedidoJson['created_at'] ??
              '',
        );

        pedidosNuevos.add(
          Pedido(
            numero: numero,
            mesa: mesa,
            hora: hora,
            productos: productos,
            preparando: _estaPreparando(pedidoJson['estado']),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        pedidos = pedidosNuevos;
        cargando = false;
        errorCarga = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        errorCarga = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _estaPreparando(dynamic estado) {
    final String valor =
        (estado ?? '').toString().toLowerCase().trim();

    return valor == 'preparando' ||
        valor == 'en preparación' ||
        valor == 'en_preparacion';
  }

  String _formatearHora(dynamic valor) {
    final String texto = valor.toString().trim();

    if (texto.isEmpty) return '--:--';

    final RegExp horaRegex =
        RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$');

    final Match? coincidencia = horaRegex.firstMatch(texto);

    if (coincidencia != null) {
      return '${coincidencia.group(1)!.padLeft(2, '0')}:'
          '${coincidencia.group(2)!}';
    }

    final DateTime? fecha = DateTime.tryParse(texto);

    if (fecha != null) {
      return '${fecha.hour.toString().padLeft(2, '0')}:'
          '${fecha.minute.toString().padLeft(2, '0')}';
    }

    return texto;
  }

 Future<void> actualizarEstadoPedido(
  Pedido pedido,
  int nuevoEstado,
) async {
  if (pedido.guardandoEstado) return;

  setState(() {
    pedido.guardandoEstado = true;
    errorCarga = null;
  });

  try {
    final respuesta = await http
        .patch(
          Uri.parse(
            '$apiBaseUrl/api/cocina/pedidos/${pedido.numero}/estado',
          ),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fk_id_estado': nuevoEstado}),
        )
        .timeout(const Duration(seconds: 15));

    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300) {
      throw Exception(
        'El servidor respondió con el código ${respuesta.statusCode}. '
        '${respuesta.body}',
      );
    }

    if (!mounted) return;

    setState(() {
      pedido.guardandoEstado = false;

      if (nuevoEstado == 2) {
        pedido.preparando = true;
      } else if (nuevoEstado == 3) {
        pedidos.remove(pedido);
        pedidosAnteriores.removeWhere(
          (anterior) => anterior.numero == pedido.numero,
        );
        pedidosAnteriores.insert(0, pedido);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nuevoEstado == 2
              ? 'Pedido #${pedido.numero} marcado como Preparando.'
              : 'Pedido #${pedido.numero} marcado como Listo.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      pedido.guardandoEstado = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo actualizar el pedido: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void comenzarPreparacion(Pedido pedido) {
  actualizarEstadoPedido(pedido, 2);
}

void pedidoListo(Pedido pedido) {
  actualizarEstadoPedido(pedido, 3);
}

  void mostrarPedidosAnteriores() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Pedidos anteriores del día',
            style: TextStyle(
              color: azulOscuro,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 520,
            child: pedidosAnteriores.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Todavía no hay pedidos finalizados.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: pedidosAnteriores.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final Pedido pedido = pedidosAnteriores[index];

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: azul,
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          'Pedido #${pedido.numero.toString().padLeft(4, '0')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${pedido.mesa} · ${pedido.hora}\n'
                          '${pedido.productos.length} producto(s)',
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: azulOscuro,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 66,
        title: const Row(
          children: [
            Icon(Icons.restaurant, size: 29),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Pedidos en Cocina',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar pedidos',
            onPressed: cargando ? null : cargarPedidos,
            icon: const Icon(Icons.refresh, size: 28),
          ),
          const SizedBox(width: 4),
          Container(
            width: 1,
            height: 28,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(vertical: 18),
          ),
          IconButton(
            tooltip: 'Pedidos anteriores',
            onPressed: mostrarPedidosAnteriores,
            icon: const Icon(Icons.history, size: 29),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (errorCarga != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorCarga!,
                        style: TextStyle(
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reintentar',
                      onPressed: cargarPedidos,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            if (cargando)
              const LinearProgressIndicator(
                minHeight: 3,
                color: azul,
              ),
            Expanded(
              child: pedidos.isEmpty
                  ? _pantallaVacia()
                  : RefreshIndicator(
                      onRefresh: cargarPedidos,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final bool celular =
                              constraints.maxWidth < 650;

                          if (celular) {
                            return ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                12, 12, 12, 18,
                              ),
                              itemCount: pedidos.length,
                              itemBuilder: (context, index) {
                                final Pedido pedido = pedidos[index];

                                return _TarjetaPedido(
                                  pedido: pedido,
                                  celular: true,
                                  onPreparar: () =>
                                      comenzarPreparacion(pedido),
                                  onListo: () => pedidoListo(pedido),
                                );
                              },
                            );
                          }

                          return GridView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              18, 16, 18, 18,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 520,
                              mainAxisExtent: 465,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: pedidos.length,
                            itemBuilder: (context, index) {
                              final Pedido pedido = pedidos[index];

                              return _TarjetaPedido(
                                pedido: pedido,
                                celular: false,
                                onPreparar: () =>
                                    comenzarPreparacion(pedido),
                                onListo: () => pedidoListo(pedido),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pantallaVacia() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(color: azul),
      );
    }

    return RefreshIndicator(
      onRefresh: cargarPedidos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      errorCarga != null
                          ? Icons.cloud_off_outlined
                          : Icons.restaurant_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorCarga != null
                          ? 'No se pudieron cargar los pedidos'
                          : 'No hay pedidos pendientes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorCarga != null
                          ? 'Revisá la conexión con el servidor.'
                          : 'Los pedidos nuevos aparecerán aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: cargarPedidos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPedido extends StatelessWidget {
  final Pedido pedido;
  final bool celular;
  final VoidCallback onPreparar;
  final VoidCallback onListo;

  const _TarjetaPedido({
    required this.pedido,
    required this.celular,
    required this.onPreparar,
    required this.onListo,
  });

  static const Color azulOscuro = Color(0xFF002548);
  static const Color azul = Color(0xFF0870A5);
  static const Color naranja = Color(0xFFE58A24);
  static const Color verde = Color(0xFF26834A);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: celular ? 12 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: azul, width: 1.5),
      ),
      child: Column(
        mainAxisSize:
            celular ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezado(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              height: 1,
              color: Color(0xFFCCCCCC),
            ),
          ),
          if (celular)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0;
                      i < pedido.productos.length;
                      i++) ...[
                    _ProductoPedido(
                      producto: pedido.productos[i],
                      celular: true,
                    ),
                    if (i < pedido.productos.length - 1)
                      const Divider(
                        height: 16,
                        color: Color(0xFFCCCCCC),
                      ),
                  ],
                ],
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                itemCount: pedido.productos.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 14,
                  color: Color(0xFFCCCCCC),
                ),
                itemBuilder: (context, index) {
                  return _ProductoPedido(
                    producto: pedido.productos[index],
                    celular: false,
                  );
                },
              ),
            ),
          _botones(),
        ],
      ),
    );
  }

  Widget _encabezado() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.receipt_long,
            color: azul,
            size: 29,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido #${pedido.numero.toString().padLeft(4, '0')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: azulOscuro,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
  children: [
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        pedido.mesa,
        style: TextStyle(
          color: Colors.white,
          fontSize: celular ? 12 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    const SizedBox(width: 8),
    Text(
      pedido.hora,
      style: const TextStyle(
        color: Color(0xFF424242),
        fontSize: 13,
      ),
    ),
  ],
),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: pedido.preparando
                  ? const Color(0xFFFFE7C2)
                  : const Color(0xFFDCEAF5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              pedido.preparando ? 'PREPARANDO' : 'RECIBIDO',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: pedido.preparando ? naranja : azul,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botones() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: SizedBox(
        width: double.infinity,
        child: pedido.preparando
            ? ElevatedButton.icon(
                onPressed: onListo,
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 19,
                ),
                label: const Text('PEDIDO LISTO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: verde,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: const StadiumBorder(),
                ),
              )
            : ElevatedButton.icon(
                onPressed: onPreparar,
                icon: const Icon(
                  Icons.restaurant,
                  size: 19,
                ),
                label: const Text('PREPARAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulOscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
      ),
    );
  }
}

class _ProductoPedido extends StatelessWidget {
  final Producto producto;
  final bool celular;

  const _ProductoPedido({
    required this.producto,
    required this.celular,
  });

  static const Color azulOscuro = Color(0xFF002548);
  static const Color azul = Color(0xFF0870A5);
  static const Color verde = Color(0xFF26834A);

  @override
  Widget build(BuildContext context) {
    final double anchoImagen = celular ? 94 : 118;
    final double altoImagen = celular ? 94 : 118;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La imagen ahora queda a la izquierda.
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: anchoImagen,
              height: altoImagen,
              child: _ImagenProducto(imagen: producto.imagen),
            ),
          ),
          const SizedBox(width: 12),

          // Los datos aprovechan el espacio a la derecha.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 29,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: azulOscuro,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${producto.cantidad}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          producto.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: azulOscuro,
                            fontSize: celular ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                const Row(
                  children: [
                    Icon(Icons.check, color: verde, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'INCLUYE',
                      style: TextStyle(
                        color: verde,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  producto.detalle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF424242),
                    fontSize: celular ? 12 : 14,
                    height: 1.25,
                  ),
                ),
                if (producto.observacion.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  const Text(
                    'OBSERVACIÓN',
                    style: TextStyle(
                      color: azul,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    producto.observacion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF424242),
                      fontSize: celular ? 12 : 14,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Construye posibles direcciones para las imágenes guardadas en Laravel.
/// También prueba una segunda ruta si la primera no existe.
class _ImagenProducto extends StatelessWidget {
  final String imagen;

  const _ImagenProducto({required this.imagen});

  static const Color fondoImagen = Color(0xFFE8E8E8);

  List<String> _posiblesUrls() {
  final String ruta = imagen.trim();

  if (ruta.isEmpty) return [];

  if (ruta.startsWith('https://') || ruta.startsWith('http://')) {
    return [ruta];
  }

  String limpia = ruta.replaceAll('\\', '/');

  while (limpia.startsWith('/')) {
    limpia = limpia.substring(1);
  }

  if (limpia.startsWith('public/')) {
    limpia = limpia.substring('public/'.length);
  }

  if (limpia.startsWith('storage/')) {
    limpia = limpia.substring('storage/'.length);
  }

  return [
    '$servidorLaravel/api/imagen-producto/${Uri.encodeFull(limpia)}',
    '$servidorLaravel/storage/${Uri.encodeFull(limpia)}',
  ];
}

  @override
  Widget build(BuildContext context) {
    final List<String> urls = _posiblesUrls();

    if (urls.isEmpty) {
      return _imagenVacia();
    }

    return _ImagenConAlternativas(urls: urls);
  }

  Widget _imagenVacia() {
    return Container(
      color: fondoImagen,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: Color(0xFF999999),
        size: 34,
      ),
    );
  }
}

class _ImagenConAlternativas extends StatefulWidget {
  final List<String> urls;

  const _ImagenConAlternativas({required this.urls});

  @override
  State<_ImagenConAlternativas> createState() =>
      _ImagenConAlternativasState();
}

class _ImagenConAlternativasState
    extends State<_ImagenConAlternativas> {
  int indice = 0;

  @override
  Widget build(BuildContext context) {
    if (indice >= widget.urls.length) {
      return Container(
        color: const Color(0xFFE8E8E8),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF999999),
          size: 34,
        ),
      );
    }

    return Image.network(
      widget.urls[indice],
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          if (indice < widget.urls.length - 1) {
            setState(() {
              indice++;
            });
          }
        });

        return Container(
          color: const Color(0xFFE8E8E8),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF0870A5),
            ),
          ),
        );
      },
    );
  }
}
