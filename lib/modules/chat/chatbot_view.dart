import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../utils/agro_alerts.dart';

/// --- VOZ DO CURRAL: ASSISTENTE VIRTUAL EDGE AI ---
/// Este widget simula um processamento de linguagem natural (NLP) 100% offline.
/// Ele atua como uma interface de conversação para os motores de Machine Learning
/// e Recomendação Genética do aplicativo AgroGen Crateús.

class Message {
  final String text;
  final bool isUser;
  final DateTime time;

  Message({required this.text, required this.isUser, required this.time});
}

class ChatbotView extends StatefulWidget {
  @override
  _ChatbotViewState createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Mensagem de boas-vindas inicial
    _messages.add(Message(
      text: "Olá, produtor! Eu sou a Voz do Curral. 🤠\nComo posso ajudar seu rebanho hoje? Posso calcular chances de prenhez ou sugerir cruzamentos genéticos.",
      isUser: false,
      time: DateTime.now(),
    ));
  }

  /// --- MOTOR DE NLP LOCAL (BASEADO EM INTENÇÕES) ---
  /// Esta função analisa as palavras-chave para disparar as lógicas do sistema.
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true, time: DateTime.now()));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Simula tempo de processamento da "IA Embarcada"
    Timer(const Duration(milliseconds: 1500), () {
      String response = _processOfflineIntelligence(text.toLowerCase());
      setState(() {
        _isTyping = false;
        _messages.add(Message(text: response, isUser: false, time: DateTime.now()));
      });
      _scrollToBottom();
    });
  }

  String _processOfflineIntelligence(String input) {
    // 1. INTENÇÃO: PREDIÇÃO DE PRENHEZ (Integração simbólica com ML)
    if (input.contains("prenhez") || input.contains("chance") || 
        input.contains("inseminar") || input.contains("sucesso")) {
      return "🔍 Analisando dados bioclimáticos...\n\nO THI atual em Crateús é de 79.2. Para vacas exóticas, a chance de sucesso na inseminação agora é de apenas 22%. Recomendo aguardar o período da noite onde o THI cairá para 68, aumentando sua taxa para 84%!";
    }

    // 2. INTENÇÃO: RECOMENDAÇÃO GENÉTICA (Integração simbólica com Heurística)
    if (input.contains("touro") || input.contains("macho") || 
        input.contains("reprodutor") || input.contains("cruzamento") || input.contains("match")) {
      return "🧬 Verificando linhagens no banco de dados...\n\nIdentifiquei que para o seu manejo EXTENSIVO, o match perfeito é o touro 'Sertão Valente'. Ele possui Score 92.5 e 0% de consanguinidade com seu lote atual. Evite o 'Chubby_Bull', pois detectamos parentesco de 2º grau.";
    }

    // 3. FALLBACK (Caso não entenda)
    return "Não entendi muito bem. Tente perguntar sobre 'chance de prenhez' ou 'melhor reprodutor' para eu ativar meus motores de inteligência! 🚜";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F0),
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.psychology, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Voz do Curral", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Online • Edge IA", style: TextStyle(fontSize: 11, color: Colors.green[100])),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text("Voz do Curral está processando...", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF558B2F) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 0),
            bottomRight: Radius.circular(message.isUser ? 0 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: message.isUser ? Colors.white : Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('HH:mm').format(message.time),
                style: TextStyle(color: message.isUser ? Colors.white60 : Colors.grey, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration(
                  hintText: "Diga algo ou peça uma análise...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPress: () => AgroAlert.show(title: "Comando de Voz", message: "Gravando áudio... (Tecnologia Speech-to-Text Offline ativada)."),
            child: CircleAvatar(
              backgroundColor: Colors.green[800],
              child: IconButton(
                icon: const Icon(Icons.mic, color: Colors.white),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
