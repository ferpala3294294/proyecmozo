import 'package:flutter/material.dart';

void main() {
  runApp(const ProyecMozo());
}

class ProyecMozo extends StatelessWidget {
  const ProyecMozo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ProyecMozo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const PedidosCocinaScreen(),
    );
  }
}

class Pedido {
  final String numero;
  final String mesa;
  final String hora;

  final int cantidad1;
  final String producto1;
  final String detalle1;

  final int cantidad2;
  final String producto2;
  final String detalle2;

  final String observacion;

  bool preparando;

  Pedido({
    required this.numero,
    required this.mesa,
    required this.hora,
    required this.cantidad1,
    required this.producto1,
    required this.detalle1,
    required this.cantidad2,
    required this.producto2,
    required this.detalle2,
    required this.observacion,
    this.preparando = false,
  });
}

class PedidosCocinaScreen extends StatefulWidget {
  const PedidosCocinaScreen({super.key});

  @override
  State<PedidosCocinaScreen> createState() =>
      _PedidosCocinaScreenState();
}

class _PedidosCocinaScreenState
    extends State<PedidosCocinaScreen> {
  final List<Pedido> pedidos = [
    Pedido(
      numero: '#0005',
      mesa: 'Mesa 2',
      hora: '12:34 PM',

      cantidad1: 2,
      producto1: 'Hamburguesa completa',
      detalle1:
          'Carne • Queso • Lechuga • Tomate • Cebolla',

      cantidad2: 1,
      producto2: 'Pizza especial',
      detalle2:
          'Mozzarella • Jamón • Aceitunas • Morrón',

      observacion: 'Sin lechuga por favor.',
    ),

    Pedido(
      numero: '#0006',
      mesa: 'Mesa 4',
      hora: '12:36 PM',

      cantidad1: 3,
      producto1: 'Empanadas (carne)',
      detalle1: '3 unidades',

      cantidad2: 1,
      producto2: 'Papas fritas',
      detalle2: 'Porción',

      observacion: 'Cliente sin cebolla.',
    ),

    Pedido(
      numero: '#0003',
      mesa: 'Mesa 5',
      hora: '12:20 PM',

      cantidad1: 1,
      producto1: 'Sándwich de jamón y queso',
      detalle1: 'Jamón • Queso',

      cantidad2: 2,
      producto2: 'Papas fritas',
      detalle2: 'Porción',

      observacion: 'Sin sal.',
    ),
  ];

  void prepararPedido(Pedido pedido) {
    setState(() {
      pedido.preparando = true;
    });
  }

  void pedidoListo(Pedido pedido) {
    setState(() {
      pedidos.remove(pedido);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // =====================================================
            // ENCABEZADO
            // =====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              color: const Color(0xFF002548),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Pedidos en Cocina',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 32,
                  ),
                ],
              ),
            ),

            // =====================================================
            // LISTA DE PEDIDOS
            // =====================================================
            Expanded(
              child: pedidos.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay pedidos pendientes',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: pedidos.length,
                      itemBuilder: (context, index) {
                        final pedido = pedidos[index];

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 16),
                          child: PedidoCard(
                            pedido: pedido,
                            onPreparar: () {
                              prepararPedido(pedido);
                            },
                            onListo: () {
                              pedidoListo(pedido);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onPreparar;
  final VoidCallback onListo;

  const PedidoCard({
    super.key,
    required this.pedido,
    required this.onPreparar,
    required this.onListo,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorEstado = pedido.preparando
        ? const Color(0xFFFF8C00)
        : const Color(0xFF0065A8);

    final String estado =
        pedido.preparando ? 'PREPARANDO' : 'RECIBIDO';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pedido.preparando
            ? const Color(0xFFFFF3E0)
            : Colors.white,
        border: Border.all(
          color: colorEstado,
          width: pedido.preparando ? 4 : 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: pedido.preparando
                ? Colors.orange.withOpacity(0.25)
                : Colors.black.withOpacity(0.08),
            blurRadius: pedido.preparando ? 12 : 5,
            spreadRadius: pedido.preparando ? 2 : 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // =======================================================
          // CABECERA
          // =======================================================
          Row(
            children: [
              Icon(
                pedido.preparando
                    ? Icons.restaurant
                    : Icons.receipt_long,
                color: colorEstado,
                size: 30,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido ${pedido.numero}',
                      style: const TextStyle(
                        color: Color(0xFF002548),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pedido.mesa}  •  ${pedido.hora}',
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 25),

          // =======================================================
          // PRODUCTOS
          // =======================================================
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Producto(
                  cantidad: pedido.cantidad1,
                  nombre: pedido.producto1,
                  detalle: pedido.detalle1,
                ),
              ),

              Container(
                width: 1,
                height: 100,
                color: Colors.grey.shade300,
              ),

              Expanded(
                child: _Producto(
                  cantidad: pedido.cantidad2,
                  nombre: pedido.producto2,
                  detalle: pedido.detalle2,
                ),
              ),

              Container(
                width: 1,
                height: 100,
                color: Colors.grey.shade300,
              ),

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 15),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OBSERVACIÓN',
                        style: TextStyle(
                          color: colorEstado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pedido.observacion,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // =======================================================
          // BOTÓN
          // =======================================================
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: pedido.preparando
                  ? onListo
                  : onPreparar,
              icon: Icon(
                pedido.preparando
                    ? Icons.check
                    : Icons.restaurant,
                color: Colors.white,
              ),
              label: Text(
                pedido.preparando
                    ? 'PEDIDO LISTO'
                    : 'PREPARAR',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: pedido.preparando
                    ? const Color(0xFF159447)
                    : const Color(0xFF002548),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Producto extends StatelessWidget {
  final int cantidad;
  final String nombre;
  final String detalle;

  const _Producto({
    required this.cantidad,
    required this.nombre,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF002548),
                  borderRadius:
                      BorderRadius.circular(6),
                ),
                child: Text(
                  '${cantidad}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    color: Color(0xFF002548),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            '✓ INCLUYE',
            style: TextStyle(
              color: Color(0xFF159447),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            detalle,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}