import '../models/modelos.dart';

List<Propiedad> propiedades = [
  Propiedad(
    id: '1', nombre: 'Casa Principal',
    direccion: 'Col. Kennedy, Blvd. Suyapa', colonia: 'Tegucigalpa',
    servicios: [TipoServicio.agua, TipoServicio.luz],
    lecturas: [
      Lectura(mes: 'Jun 2023', valor: 2982.0, tipo: TipoServicio.agua, fecha: DateTime(2023, 6, 1)),
      Lectura(mes: 'Jul 2023', valor: 3010.0, tipo: TipoServicio.agua, fecha: DateTime(2023, 7, 1)),
      Lectura(mes: 'Ago 2023', valor: 3040.5, tipo: TipoServicio.agua, fecha: DateTime(2023, 8, 1)),
      Lectura(mes: 'Sep 2023', valor: 3070.3, tipo: TipoServicio.agua, fecha: DateTime(2023, 9, 1)),
      Lectura(mes: 'Oct 2023', valor: 3080.8, tipo: TipoServicio.agua, fecha: DateTime(2023, 10, 1)),
      Lectura(mes: 'Nov 2023', valor: 3110.8, tipo: TipoServicio.agua, fecha: DateTime(2023, 11, 1)),
      Lectura(mes: 'Dic 2023', valor: 3145.2, tipo: TipoServicio.agua, fecha: DateTime(2023, 12, 1)),
      Lectura(mes: 'Jun 2023', valor: 17610.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 6, 1)),
      Lectura(mes: 'Jul 2023', valor: 17800.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 7, 1)),
      Lectura(mes: 'Ago 2023', valor: 17980.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 8, 1)),
      Lectura(mes: 'Sep 2023', valor: 18140.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 9, 1)),
      Lectura(mes: 'Oct 2023', valor: 18320.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 10, 1)),
      Lectura(mes: 'Nov 2023', valor: 18557.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 11, 1)),
      Lectura(mes: 'Dic 2023', valor: 18742.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 12, 1)),
    ],
  ),
  Propiedad(
    id: '2', nombre: 'Apto Centro',
    direccion: 'Blv. Morazán, Ed. Torres', colonia: 'Tegucigalpa',
    servicios: [TipoServicio.agua, TipoServicio.luz, TipoServicio.gas],
    lecturas: [
      Lectura(mes: 'Aug 2023', valor: 1182.0, tipo: TipoServicio.agua, fecha: DateTime(2023, 8, 1)),
      Lectura(mes: 'Sep 2023', valor: 1200.0, tipo: TipoServicio.agua, fecha: DateTime(2023, 9, 1)),
      Lectura(mes: 'Oct 2023', valor: 1218.0, tipo: TipoServicio.agua, fecha: DateTime(2023, 10, 1)),
      Lectura(mes: 'Nov 2023', valor: 1240.0, tipo: TipoServicio.agua, fecha: DateTime(2023, 11, 1)),
      Lectura(mes: 'Dic 2023', valor: 1258.0, tipo: TipoServicio.agua, fecha: DateTime(2023, 12, 1)),
      Lectura(mes: 'Aug 2023', valor: 5244.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 8, 1)),
      Lectura(mes: 'Sep 2023', valor: 5400.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 9, 1)),
      Lectura(mes: 'Oct 2023', valor: 5560.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 10, 1)),
      Lectura(mes: 'Nov 2023', valor: 5710.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 11, 1)),
      Lectura(mes: 'Dic 2023', valor: 5890.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 12, 1)),
      Lectura(mes: 'Aug 2023', valor: 390.0, tipo: TipoServicio.gas, fecha: DateTime(2023, 8, 1)),
      Lectura(mes: 'Sep 2023', valor: 400.0, tipo: TipoServicio.gas, fecha: DateTime(2023, 9, 1)),
      Lectura(mes: 'Oct 2023', valor: 410.6, tipo: TipoServicio.gas, fecha: DateTime(2023, 10, 1)),
      Lectura(mes: 'Nov 2023', valor: 414.6, tipo: TipoServicio.gas, fecha: DateTime(2023, 11, 1)),
      Lectura(mes: 'Dic 2023', valor: 427.4, tipo: TipoServicio.gas, fecha: DateTime(2023, 12, 1)),
    ],
  ),
  Propiedad(
    id: '3', nombre: 'Local Comercial',
    direccion: 'Mall Multiplaza, Loc. 214', colonia: 'Tegucigalpa',
    servicios: [TipoServicio.luz],
    lecturas: [
      Lectura(mes: 'Sep 2023', valor: 9500.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 9, 1)),
      Lectura(mes: 'Oct 2023', valor: 9800.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 10, 1)),
      Lectura(mes: 'Nov 2023', valor: 10100.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 11, 1)),
      Lectura(mes: 'Dic 2023', valor: 10550.0, tipo: TipoServicio.luz, fecha: DateTime(2023, 12, 1)),
    ],
  ),
];

const List<Tip> tips = [
  Tip(titulo: 'Revisá fugas silenciosas', descripcion: 'Poné colorante en el tanque del baño sin jalar. Si el color llega al inodoro, hay fuga — puede desperdiciar 200 litros al día sin que te des cuenta.', emoji: '🔧', tipo: TipoServicio.agua, ahorroEstimado: 350),
  Tip(titulo: 'Ciclo corto en la lavadora', descripcion: 'El ciclo corto ahorra 40% de agua y energía vs el ciclo normal. Para ropa del día a día, es más que suficiente.', emoji: '🫧', tipo: TipoServicio.agua, ahorroEstimado: 150),
  Tip(titulo: 'Apagá el aire en las noches', descripcion: 'El A/C puede consumir hasta el 60% de tu factura ENEE. Con ventilador de techo de noche ahorrás entre L.300 y L.500 al mes fácilmente.', emoji: '❄️', tipo: TipoServicio.luz, ahorroEstimado: 500),
  Tip(titulo: 'LED + bajar de bloque = ahorro doble', descripcion: 'Los LED consumen 75% menos. Si bajás de 160 a 120 kWh/mes, también bajás de bloque tarifario ENEE — el ahorro se multiplica.', emoji: '💡', tipo: TipoServicio.luz, ahorroEstimado: 280),
  Tip(titulo: 'Hora pico ENEE: 6–9 PM', descripcion: 'La red eléctrica de Honduras está más sobrecargada de 6 a 9 PM. Evitá plancha, horno o lavadora en esos horarios para ayudar a la red y prevenir cortes.', emoji: '⏰', tipo: TipoServicio.luz, ahorroEstimado: 180),
  Tip(titulo: 'Desconectá lo que no usás', descripcion: 'Aparatos en standby (TV, cargadores, microondas) pueden consumir hasta 10% de tu factura. Usá regletas con interruptor o desconectalos al salir.', emoji: '🔌', tipo: TipoServicio.luz, ahorroEstimado: 120),
  Tip(titulo: 'Gas: calentá solo lo necesario', descripcion: 'Calentá el agua justo antes de usarla. Un termo lleno sin usar pierde temperatura y el quemador recalienta sin que lo notes, gastando gas innecesariamente.', emoji: '🚿', tipo: TipoServicio.gas, ahorroEstimado: 250),
  Tip(titulo: 'Reclamá lecturas estimadas', descripcion: 'La ENEE a veces estima cuando el lector no puede acceder al medidor. Tomá tu propia foto cada mes y reclamá si la factura no coincide con tu lectura real.', emoji: '📸', ahorroEstimado: 200),
  Tip(titulo: 'Compará mes a mes siempre', descripcion: 'Si el consumo sube más de 20% sin razón, hay un problema — fuga, aparato viejo o lectura estimada incorrecta. Detectarlo a tiempo puede ahorrar cientos de lempiras.', emoji: '📊', ahorroEstimado: 400),
];

const List<String> meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];

// Datos comparativos de hogares similares (benchmark Honduras 2023)
const Map<String, double> benchmarkHogares = {
  'agua_promedio_hn':   28.0,  // m³/mes hogar promedio Honduras
  'luz_promedio_hn':   185.0,  // kWh/mes hogar promedio Honduras
  'agua_eficiente':    18.0,   // m³/mes hogar eficiente
  'luz_eficiente':    120.0,   // kWh/mes hogar eficiente
};
