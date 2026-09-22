# Aplicativo móvel

Aplicativo Flutter do Zelo, inicialmente direcionado ao Android. A versão atual
contém tema Material 3 e um fluxo manual de medicamentos validado com dados em
memória:

- resumo dinâmico da farmácia doméstica;
- listagem ordenada por validade;
- cadastro, edição, detalhes e remoção;
- estados vazio e erro simulado com nova tentativa;
- classificação como válido, próximo do vencimento ou vencido.

A janela padrão de proximidade é de 30 dias. A comparação usa somente a data, e
o medicamento que vence hoje ainda não é classificado como vencido.

O armazenamento não é persistente: os dados voltam ao estado inicial quando o
aplicativo é reiniciado. Persistência e integração com a API Zelo pertencem ao
marco do backend.

A abertura contém splash Android com fundo monocromático, animação Flutter de
800 ms somente com o símbolo oficial, bootstrap recuperável iniciado em paralelo,
onboarding de três páginas e autenticação simulada. A animação é ignorada
quando a redução de movimento está ativa. Se o bootstrap ultrapassar a animação,
o aplicativo mostra o carregamento real, sem espera artificial.

O onboarding usa composições de superfícies, trajetos e ícones com o ativo
oficial, preservando Pular, Próximo, Voltar e Começar. Nenhuma permissão é
solicitada nesse fluxo.

O onboarding persiste `onboarding_completed`. A autenticação simulada oferece
login, cadastro, recuperação genérica, restauração de sessão, demonstração e
logout, persistindo apenas `simulated_session_active`. Nome, e-mail e senha não
são armazenados. Essa simulação não representa autenticação segura; API real,
isolamento de usuários e tokens protegidos pertencem ao M4.

A navegação autenticada usa Início, Descartar, Histórico e Conta. A lista de
Medicamentos abre por “Ver todos” na Home; Descartar informa que a integração
EcoMed é futura; Histórico permanece vazio e sem persistência real; Conta
identifica a sessão simulada, não exibe dados pessoais e contém o logout.

A única dependência direta adicionada no M2 é `shared_preferences 2.5.5`, usada
atrás de abstrações testáveis. Os testes usam implementações em memória e não
dependem do plugin ou de dados externos.

## Validação atual

- `dart format`: aprovado em 21/09/2026;
- `flutter analyze`: sem problemas em 21/09/2026;
- `flutter test`: 47 testes aprovados em 21/09/2026;
- `flutter build web`: aprovado em 21/09/2026.

O layout foi exercitado automaticamente em 390 × 844 e 320 × 568, com texto
ampliado no onboarding e teclado aberto no login, sem overflow. O servidor Web
local iniciou, mas o ambiente não ofereceu navegador controlável para inspeção
visual interativa. Android SDK, `adb`, `sdkmanager` e o comando `java` continuam
ausentes; por isso o APK, a splash nativa e a transição Android → Flutter
permanecem sem validação real ou emulada. A reconciliação no Figma e os textos
de termos de uso e política de privacidade também permanecem pendentes.
