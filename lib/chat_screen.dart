import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDoctorScreen extends StatefulWidget {
  final String pacienteId;
  final String nombrePaciente;
  final String miUid;
  final String miNombre;
  final String miRol;

  const ChatDoctorScreen({
    super.key,
    required this.pacienteId,
    required this.nombrePaciente,
    required this.miUid,
    required this.miNombre,
    required this.miRol,
  });

  @override
  State<ChatDoctorScreen> createState() => _ChatDoctorScreenState();
}

class _ChatDoctorScreenState extends State<ChatDoctorScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool enviando = false;

  CollectionReference get _chat => FirebaseFirestore.instance
      .collection('usuarios')
      .doc(widget.pacienteId)
      .collection('chatDoctor');

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty || enviando) return;

    setState(() => enviando = true);
    _mensajeController.clear();

    try {
      // Usar hora local en lugar de serverTimestamp
      await _chat.add({
        'texto': texto,
        'fechaHora': Timestamp.fromDate(DateTime.now()),
        'enviadoPor': widget.miRol,
        'remitenteNombre': widget.miNombre,
        'leido': false,
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Error al enviar mensaje: $e');
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  String _hora(DateTime fecha) {
    final h = fecha.hour.toString().padLeft(2, '0');
    final m = fecha.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fechaCorta(DateTime fecha) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF6A93BE);
    const azulOscuro = Color(0xFF2C3E6B);

    final titulo = widget.miRol == 'doctor'
        ? 'Chat con ${widget.nombrePaciente}'
        : 'Mensajes con el doctor';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: azul),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: azulOscuro,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (widget.miRol == 'doctor')
              Text(
                widget.nombrePaciente,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),

      body: Column(
        children: [

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chat
                  .orderBy('fechaHora', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: azul),
                  );
                }

                final mensajes = snapshot.data?.docs ?? [];

                if (mensajes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Aún no hay mensajes',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Envía el primer mensaje',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                // Marcar como leídos
                for (final doc in mensajes) {
                  final data = doc.data() as Map<String, dynamic>;
                  final enviadoPor = data['enviadoPor'] ?? '';
                  final leido = data['leido'] ?? true;
                  if (enviadoPor != widget.miRol && !leido) {
                    doc.reference.update({'leido': true});
                  }
                }

                // Scroll al final
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: mensajes.length,
                  itemBuilder: (context, i) {
                    final data =
                        mensajes[i].data() as Map<String, dynamic>;
                    final esMio =
                        data['enviadoPor'] == widget.miRol;

                    // Convertir a hora local
                    final fecha = data['fechaHora'] != null
                        ? (data['fechaHora'] as dynamic)
                            .toDate()
                            .toLocal()
                        : DateTime.now();

                    final texto = data['texto'] ?? '';
                    final nombre = data['remitenteNombre'] ?? '';

                    bool mostrarFecha = false;
                    if (i == 0) {
                      mostrarFecha = true;
                    } else {
                      final anterior = mensajes[i - 1].data()
                          as Map<String, dynamic>;
                      // También toLocal() en fecha anterior
                      final fechaAnterior =
                          anterior['fechaHora'] != null
                              ? (anterior['fechaHora'] as dynamic)
                                  .toDate()
                                  .toLocal()
                              : DateTime.now();
                      if (fecha.day != fechaAnterior.day ||
                          fecha.month != fechaAnterior.month) {
                        mostrarFecha = true;
                      }
                    }

                    return Column(
                      children: [
                        if (mostrarFecha)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                _fechaCorta(fecha),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),

                        Align(
                          alignment: esMio
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: esMio
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!esMio)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4, bottom: 2),
                                  child: Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width *
                                          0.72,
                                ),
                                margin:
                                    const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: esMio ? azul : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight:
                                        const Radius.circular(16),
                                    bottomLeft: Radius.circular(
                                        esMio ? 16 : 4),
                                    bottomRight: Radius.circular(
                                        esMio ? 4 : 16),
                                  ),
                                  border: esMio
                                      ? null
                                      : Border.all(
                                          color:
                                              const Color(0xFFE0E0E0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  texto,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: esMio
                                        ? Colors.white
                                        : const Color(0xFF2C3E6B),
                                    height: 1.4,
                                  ),
                                ),
                              ),

                              // Hora en local
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8, left: 4, right: 4),
                                child: Text(
                                  _hora(fecha),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _enviarMensaje(),
                  ),
                ),
                const SizedBox(width: 10),

                GestureDetector(
                  onTap: enviando ? null : _enviarMensaje,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: enviando
                          ? Colors.grey.shade300
                          : azul,
                      shape: BoxShape.circle,
                    ),
                    child: enviando
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}