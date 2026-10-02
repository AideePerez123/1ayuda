// ============================================================
// GESTOR INTELIGENTE DE PEDIDOS - CAFÉ NUBE
// Versión base para DartPad
// ============================================================

import 'dart:async'; // Necesario para Future, Stream, async y await

// ============================================================
// ENUMS (valores fijos)
// ============================================================

// Categorías del catálogo
enum Categoria { bebida, comida, postre }

// Estados por los que pasa un pedido
enum EstadoPedido {
  creado,         // Recién creado, sin pagar
  pagoPendiente,  // Esperando confirmación de pago
  pagado,         // Pago confirmado
  preparando,     // En cocina
  listo,          // Listo para entregar
  entregado,      // Entregado al cliente
  cancelado,      // Cancelado
}

// ============================================================
// CLASE PRODUCTO
// ============================================================
class Producto {
  final int idProducto;        // ID único, no cambia
  final String nombre;         // Nombre del producto
  final double precio;         // Precio, no cambia
  int stock;                   // Stock, SÍ cambia al vender
  final Categoria categoria;   // Categoría (bebida/comida/postre)

  // Constructor posicional: los parámetros van en orden
  Producto(this.idProducto, this.nombre, this.precio, this.stock, this.categoria);

  // toString: imprime bonito al hacer print(producto)
  @override
  String toString() => '$nombre (Q${precio.toStringAsFixed(2)}) - stock: $stock';
}

// ============================================================
// CLASE CLIENTE
// ============================================================
class Cliente {
  final int idCliente;                 // ID único
  final String clienteNombre;          // Nombre
  final String clienteCorreo;          // Correo
  int puntos;                          // Puntos, SÍ cambia
  List<dynamic> pedidos = [];          // Historial de pedidos

  // Constructor posicional
  Cliente(this.idCliente, this.clienteNombre, this.clienteCorreo, this.puntos);

  @override
  String toString() => '$clienteNombre ($clienteCorreo) - Puntos: $puntos';
}

// ============================================================
// CLASE LINEA PEDIDO (cada producto dentro del pedido)
// ============================================================
class LineaPedido {
  final Producto producto;   // Referencia al producto
  int cantidad;              // Cantidad (SÍ cambia si se pide más)

  LineaPedido(this.producto, this.cantidad);

  // get subtotal = propiedad calculada (precio × cantidad)
  double get subtotal => producto.precio * cantidad;

  @override
  String toString() =>
      '$cantidad x ${producto.nombre} ......... Q${subtotal.toStringAsFixed(2)}';
}

// ============================================================
// CLASE PEDIDO (la más importante)
// ============================================================
class Pedido {
  final int numero;                          // Número del pedido
  final Cliente cliente;                     // Cliente que lo hizo
  final DateTime fecha;                      // Fecha de creación
  final List<LineaPedido> _lineas = [];      // Lista PRIVADA (_) de líneas
  EstadoPedido estado = EstadoPedido.creado; // Estado inicial

  // Constructor. El : inicializa fecha automáticamente con DateTime.now()
  Pedido(this.numero, this.cliente) : fecha = DateTime.now();

  // Getter público: devuelve copia NO modificable de _lineas
  List<LineaPedido> get lineas => List.unmodifiable(_lineas);

  // ------------------ CÁLCULOS ------------------

  // fold = acumula. Empieza en 0 y suma el subtotal de cada línea
  double get subtotal =>
      _lineas.fold(0, (suma, linea) => suma + linea.subtotal);

  // Descuento: se aplica el MAYOR entre 5% y 10%
  double get descuento {
    double d1 = subtotal >= 150 ? subtotal * 0.05 : 0;       // 5% si subtotal >= 150
    double d2 = cliente.puntos >= 100 ? subtotal * 0.10 : 0; // 10% si puntos >= 100
    return d1 > d2 ? d1 : d2; // Devuelve el mayor
  }

  double get total => subtotal - descuento;

  // ------------------ AGREGAR PRODUCTO ------------------
  bool agregarProducto(Producto producto, int cantidad) {
    // Si el estado no permite modificar, retorna false
    if (estado == EstadoPedido.pagado ||
        estado == EstadoPedido.preparando ||
        estado == EstadoPedido.listo ||
        estado == EstadoPedido.entregado) {
      print('❌ No se puede modificar un pedido en estado ${estado.name}');
      return false;
    }

    // Validar cantidad
    if (cantidad <= 0) {
      print('❌ La cantidad debe ser mayor a cero');
      return false;
    }

    // Validar stock
    if (cantidad > producto.stock) {
      print('❌ Stock insuficiente de ${producto.nombre}. Disponible: ${producto.stock}');
      return false;
    }

    // ¿Ya existe el producto en el pedido?
    for (var linea in _lineas) {
      if (linea.producto.idProducto == producto.idProducto) {
        // Verificar que la suma no supere stock
        if (linea.cantidad + cantidad > producto.stock) {
          print('❌ Stock insuficiente');
          return false;
        }
        linea.cantidad += cantidad;
        print('✅ ${producto.nombre} actualizado a ${linea.cantidad} unidades');
        return true;
      }
    }

    // Si no existe, se agrega nueva línea
    _lineas.add(LineaPedido(producto, cantidad));
    print('✅ $cantidad x ${producto.nombre} agregado');
    return true;
  }

  // ------------------ ELIMINAR PRODUCTO ------------------
  bool eliminarProducto(int productoId) {
    if (estado == EstadoPedido.pagado || estado == EstadoPedido.preparando) {
      print('❌ No se puede modificar un pedido en estado ${estado.name}');
      return false;
    }
    final antes = _lineas.length;
    _lineas.removeWhere((l) => l.producto.idProducto == productoId);
    return _lineas.length < antes;
  }

  // ------------------ RECIBO ------------------
  String generarRecibo() {
    final sb = StringBuffer();
    sb.writeln('Pedido #$numero - ${cliente.clienteNombre}');
    for (var linea in _lineas) {
      sb.writeln(linea.toString());
    }
    sb.writeln('Subtotal ................. Q${subtotal.toStringAsFixed(2)}');
    if (descuento > 0) {
      final pct = (descuento / subtotal * 100).toStringAsFixed(0);
      sb.writeln('Descuento $pct% ......... Q${descuento.toStringAsFixed(2)}');
    }
    sb.writeln('TOTAL ................. Q${total.toStringAsFixed(2)}');
    return sb.toString();
  }
}

// ============================================================
// CLASE RESULTADO PAGO
// ============================================================
class ResultadoPago {
  bool aprobado;    // true = aprobado, false = rechazado
  String mensaje;   // Mensaje descriptivo
  int codigo;       // Código de autorización

  ResultadoPago(this.aprobado, this.mensaje, this.codigo);

  @override
  String toString() =>
      aprobado ? '✅ Aprobado: AUT-$codigo' : '❌ Rechazado: $mensaje';
}

// ============================================================
// FUNCIONES ASÍNCRONAS
// ============================================================

// CARGAR CATÁLOGO (Future = un solo resultado)
Future<List<Producto>> cargarCatalogo() async {
  // Simula consulta remota con 600 ms de espera
  await Future.delayed(const Duration(milliseconds: 600));
  return [
    Producto(1, 'Crossaint', 30.0, 20, Categoria.comida),
    Producto(2, 'Shuco', 12.0, 15, Categoria.comida),
    Producto(3, 'Pan con pollo', 15.0, 10, Categoria.comida),
    Producto(4, 'Rosa de Jamaica', 8.0, 20, Categoria.bebida),
    Producto(5, 'Horchata', 10.0, 20, Categoria.bebida),
    Producto(6, 'Tamarindo', 8.0, 20, Categoria.bebida),
    Producto(7, 'Flan', 8.0, 10, Categoria.postre),
    Producto(8, 'Pastel', 15.0, 8, Categoria.postre),
    Producto(9, 'Gelatina', 5.0, 30, Categoria.postre),
  ];
}

// PROCESAR PAGO (Future)
// {bool aprobar = true} = parámetro nombrado con valor por defecto
Future<ResultadoPago> procesarPago(Pedido pedido, {bool aprobar = true}) async {
  // Si no hay productos, no se puede pagar
  if (pedido.lineas.isEmpty) {
    return ResultadoPago(false, 'El pedido está vacío', 0);
  }

  // Cambiar a pagoPendiente y esperar 500 ms
  pedido.estado = EstadoPedido.pagoPendiente;
  await Future.delayed(const Duration(milliseconds: 500));

  if (aprobar) {
    pedido.estado = EstadoPedido.pagado;
    // Descontar stock de cada producto
    for (var linea in pedido.lineas) {
      linea.producto.stock -= linea.cantidad;
    }
    return ResultadoPago(true, 'Pago exitoso', pedido.numero);
  } else {
    // Pago rechazado: vuelve a creado, no toca stock
    pedido.estado = EstadoPedido.creado;
    return ResultadoPago(false, 'Tarjeta rechazada', 0);
  }
}

// PREPARAR PEDIDO (Stream = varios resultados en el tiempo)
// async* = genera un Stream
Stream<EstadoPedido> prepararPedido(Pedido pedido) async* {
  // Solo se prepara si está pagado
  if (pedido.estado != EstadoPedido.pagado) {
    print('⚠️ El pedido no está pagado');
    return;
  }

  // Preparando
  pedido.estado = EstadoPedido.preparando;
  yield pedido.estado; // yield = emite un valor al Stream
  await Future.delayed(const Duration(milliseconds: 500));

  // Listo
  pedido.estado = EstadoPedido.listo;
  yield pedido.estado;
  await Future.delayed(const Duration(milliseconds: 500));

  // Entregado
  pedido.estado = EstadoPedido.entregado;
  yield pedido.estado;

  // Dar puntos: 1 punto por cada Q10
  int puntosGanados = (pedido.total / 10).floor();
  pedido.cliente.puntos += puntosGanados;
  pedido.cliente.pedidos.add(pedido); // Guardar en historial
  print('🎁 Puntos obtenidos: $puntosGanados');
  print('🎁 Puntos acumulados: ${pedido.cliente.puntos}');
}

// ============================================================
// MAIN (aquí se ejecuta todo)
// ============================================================
Future<void> main() async {
  print('=== CAFE NUBE ===');
  print('Cargando catalogo...');

  // 1. CARGAR CATÁLOGO
  final catalogo = await cargarCatalogo();
  print('Catalogo disponible: ${catalogo.length} productos\n');

  // 2. CREAR CLIENTE (120 puntos iniciales)
  final sofia = Cliente(1, 'Sofia Ramirez', 'sofia@mail.com', 120);

  // 3. CREAR PEDIDO #1001
  final pedido = Pedido(1001, sofia);

  // 4. AGREGAR PRODUCTOS
  pedido.agregarProducto(catalogo[0], 2); // 2 Crossaints
  pedido.agregarProducto(catalogo[4], 2); // 2 Horchatas
  pedido.agregarProducto(catalogo[7], 1); // 1 Pastel

  // Probar error: Gelatina solo hay 30, pedimos 100
  pedido.agregarProducto(catalogo[8], 100);

  // 5. RECIBO PRELIMINAR
  print('\n${pedido.generarRecibo()}');

  // 6. PROCESAR PAGO
  final pago = await procesarPago(pedido, aprobar: true);
  print(pago);

  // 7. ESCUCHAR ESTADOS CON await for
  await for (final estado in prepararPedido(pedido)) {
    print('Actualizacion: ${estado.name}');
  }

  // 8. RESUMEN FINAL
  print('\n=== RESUMEN ===');
  print(sofia);
  print('Pedidos realizados: ${sofia.pedidos.length}');
  print('\nStock actualizado:');
  for (var p in catalogo) {
    print('  $p');
  }

  // 9. CONSULTAS CON COLECCIONES
  print('\n=== CONSULTAS ===');

  // where: filtra productos con stock < 5
  final bajos = catalogo.where((p) => p.stock < 5).toList();
  print('Stock bajo: ${bajos.map((p) => p.nombre).join(', ')}');

  // fold: acumula el valor total del inventario
  final valorInventario = catalogo.fold<double>(
    0,
    (suma, p) => suma + (p.precio * p.stock),
  );
  print('Valor inventario: Q${valorInventario.toStringAsFixed(2)}');

  // sort: ordenar por precio de mayor a menor
  final ordenados = [...catalogo]..sort((a, b) => b.precio.compareTo(a.precio));
  print('Ordenados por precio: ${ordenados.map((p) => p.nombre).join(', ')}');

  // Map<Categoria, int>: agrupa productos por categoría
  final porCategoria = <Categoria, int>{};
  for (var p in catalogo) {
    porCategoria[p.categoria] = (porCategoria[p.categoria] ?? 0) + 1;
  }
  print('Productos por categoría: $porCategoria');
}
