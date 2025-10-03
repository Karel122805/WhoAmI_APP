import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TipsPage extends StatefulWidget {
  const TipsPage({super.key});
  static const route = '/tips';

  @override
  State<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  // Colores base
  static const Color blue = Color(0xFF9ED3FF);
  static const Color text = Color(0xFF111111);

  final _tts = FlutterTts();
  final _rnd = Random();

  // --- CONSEJOS ---
  final Map<String, List<String>> _tipsByCategory = {
    "Salud física": [
      "Da un paseo corto en un lugar seguro durante 10 minutos.",
      "Antes de levantarte, mueve tobillos y hombros lentamente.",
      "Toma agua a sorbos cada hora aunque no tengas sed.",
      "Si te sientes mareado, siéntate y respira tranquilo.",
      "Si te duele algo, cuéntale a tu cuidador o familiar.",
      "Haz tres estiramientos suaves después de despertar.",
      "Evita cargar cosas pesadas; pide ayuda si lo necesitas.",
      "Si te sientes cansado, descansa cinco minutos en silencio.",
    ],
    "Salud mental": [
      "Escucha una canción que te guste para relajarte.",
      "Si te sientes nervioso, cuenta del 1 al 10 despacio.",
      "Mira por la ventana y describe lo que ves en voz alta.",
      "Piensa en un recuerdo bonito y dilo con tus palabras.",
      "Si te enojas, respira lento tres veces antes de hablar.",
      "Di una frase positiva: “Hoy haré lo mejor que pueda”.",
      "Apaga ruidos fuertes si te molestan o te confunden.",
      "Pide un abrazo o compañía cuando te sientas solo.",
    ],
    "Memoria y orientación": [
      "Lleva una tarjeta con tu nombre y un número de contacto.",
      "Mira el calendario y señala la fecha de hoy con el dedo.",
      "Di en voz alta tu nombre y dónde estás ahora.",
      "Coloca tus llaves siempre en el mismo lugar.",
      "Mira fotos con nombres; repite los nombres en voz alta.",
      "Lee la lista de tareas y tacha una cuando la termines.",
      "Si no recuerdas algo, pregunta sin pena.",
      "Usa un reloj visible y mira la hora cada mañana.",
    ],
    "Rutina y sueño": [
      "Vístete a la misma hora todos los días.",
      "Prepara la ropa de mañana antes de dormir.",
      "Evita café o refrescos en la tarde para dormir mejor.",
      "Atenúa las luces 30 minutos antes de acostarte.",
      "Duerme y despierta con horarios parecidos cada día.",
      "Apaga pantallas una hora antes de dormir.",
      "Si despiertas en la noche, toma agua y vuelve a la cama.",
      "Haz una lista corta de mañana para empezar con calma.",
    ],
    "Social y familia": [
      "Llama a un familiar y cuenta cómo te fue hoy.",
      "Pide que te expliquen con palabras simples y despacio.",
      "Juega un memorama o arma un rompecabezas grande con alguien.",
      "Mira fotos familiares y di quién aparece en cada una.",
      "Saluda a tus vecinos y di tu nombre con una sonrisa.",
      "Si te cansas en una visita, pide un descanso corto.",
      "Agradece la ayuda que recibes con un ‘gracias’.",
      "Pide compañía para salir a caminar si te sientes inseguro.",
    ],
    "Entorno y seguridad": [
      "Mantén pasillos y pisos libres de objetos.",
      "Enciende una luz pequeña por la noche para ir al baño.",
      "Usa calzado cerrado para evitar resbalones.",
      "Guarda objetos filosos o peligrosos fuera de tu alcance.",
      "Coloca etiquetas en puertas: ‘Baño’, ‘Cocina’, ‘Recámara’.",
      "No subas a bancos ni sillas; pide ayuda para alcanzar algo.",
      "Verifica que la estufa esté apagada después de usarla.",
      "Lleva contigo un teléfono con números de emergencia.",
    ],
    "Alimentación e hidratación": [
      "Elige platos sencillos y come porciones pequeñas.",
      "Si un alimento no te gusta, prueba otro que conozcas.",
      "Si te distraes, apaga la televisión durante la comida.",
      "Mastica despacio y baja los cubiertos entre bocados.",
      "Usa un vaso favorito para recordar tomar agua.",
      "Agrega fruta a tu desayuno para tener energía.",
      "Si te falta apetito, come varias veces en pequeñas porciones.",
      "Avísale a tu cuidador si te cuesta tragar algún alimento.",
    ],
  };

  // Categorías dinámicas
  late final List<String> _categories;
  String _selected = "Aleatorias";
  List<String> _visible = [];

  @override
  void initState() {
    super.initState();
    _categories = ["Aleatorias", ..._tipsByCategory.keys];
    _configureTts();
    _pickVisibleTips();
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage("es-MX");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  List<String> _poolFor(String category) {
    if (category == "Aleatorias") {
      return _tipsByCategory.values.expand((x) => x).toList();
    }
    return _tipsByCategory[category] ?? const [];
  }

  void _pickVisibleTips() {
    final pool = _poolFor(_selected);
    final copy = List<String>.from(pool)..shuffle(_rnd);
    setState(() {
      _visible = copy.take(5).toList();
    });
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Consejos"), centerTitle: true, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(
                  child: Text("Selecciona una categoría",
                      style: TextStyle(color: Colors.black54)),
                ),
                SizedBox(
                  height: 38,
                  width: 220,
                  child: DropdownButtonHideUnderline(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selected,
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c == "Aleatorias"
                                          ? "— Mostrar aleatorias —"
                                          : c,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => _selected = val);
                            _pickVisibleTips();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: _visible.length,
                itemBuilder: (_, i) {
                  final tip = _visible[i];
                  return _TipCard(
                    text: tip,
                    onTap: () => _speak(tip),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selected = "Aleatorias";
                  });
                  _pickVisibleTips();
                },
                icon: const Icon(Icons.refresh),
                label: Text(
                  _selected == "Aleatorias"
                      ? "Mostrar otros consejos"
                      : "Ver consejos aleatorios",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: text,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _TipCard({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF9ED3FF), Color(0xFFE9F6FF)],
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              offset: Offset(0, 2),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15.5),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.volume_up, size: 20),
          ],
        ),
      ),
    );
  }
}
