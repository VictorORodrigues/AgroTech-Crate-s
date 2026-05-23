import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hackaton/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teste Completo de Autenticação', () {
    testWidgets('Fluxo Login -> Cadastro -> Validações', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Splash Screen
      print("--- INICIANDO TESTES ---");
      await Future.delayed(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // --- TESTE DE LOGIN ---
      print("Testando Validações de Login...");
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('O e-mail não pode estar vazio.'), findsOneWidget);
      await Future.delayed(const Duration(seconds: 1));

      // --- NAVEGANDO PARA CADASTRO ---
      print("Navegando para a tela de Cadastro...");
      // Agora usamos a KEY que é infalível
      await tester.tap(find.byKey(const Key('btn_ir_cadastro')));
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));

      // --- TESTE DE CADASTRO ---
      print("Testando Validações de Cadastro...");
      // Digita um e-mail mal formatado no cadastro
      await tester.enterText(find.byType(TextField).at(0), 'agro_user_invalido');
      await tester.enterText(find.byType(TextField).at(1), '123');
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Verifica se os erros apareceram na tela de cadastro
      expect(find.text('Digite um formato de e-mail válido.'), findsOneWidget);
      expect(find.text('A senha deve ter pelo menos 6 caracteres.'), findsOneWidget);
      
      print("--- TODOS OS TESTES PASSARAM COM SUCESSO ---");
      await Future.delayed(const Duration(seconds: 2));
    });
  });
}
