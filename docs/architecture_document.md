# Chronos

## Integrantes

* **Alfredo Luis Vieira, 1222909@sga.pucminas.br**
* **Bruno Evangelista Gomes de Azevedo, 1453105@sga.pucminas.br**
* **David Dias Pinto, 1440381@sga.pucminas.br**
* **Vinicius Salles de Oliveira, 1444802@sga.pucminas.br**


## Professores

* Artur Martins Mol
* Leonardo Vilela Cardoso

---

_Curso de Engenharia de Software, Campus Coração Eucarístico_

_Instituto de Informática e Ciências Exatas – Pontifícia Universidade de Minas Gerais (PUC MINAS), Belo Horizonte – MG – Brasil_



_**Resumo**. Escrever aqui o resumo. O resumo deve contextualizar rapidamente o trabalho, descrever seu objetivo e, ao final, 
mostrar algum resultado relevante do trabalho (até 10 linhas)._



## Histórico de Revisões

| **Data** | **Autor** | **Descrição** | **Versão** |
| --- | --- | --- | --- |
| **[dd/mm/aaaa]** | [Nome do autor] | [Descrever as principais alterações realizadas no documento, evidenciando as seções ou capítulos alterados] | [X] |
| | | | |
| | | | |

## SUMÁRIO

1. [Apresentação](#apresentacao "Apresentação") <br />
	1.1. Problema <br />
	1.2. Objetivos do trabalho <br />
	1.3. Definições e Abreviaturas <br />
 
2. [Nosso Produto](#produto "Nosso Produto") <br />
	2.1. Visão do Produto <br />
   	2.2. Nosso Produto <br />
   	2.3. Personas <br />

3. [Requisitos](#requisitos "Requisitos") <br />
	3.1. Requisitos Funcionais <br />
	3.2. Requisitos Não-Funcionais <br />
	3.3. Restrições Arquiteturais <br />
	3.4. Mecanismos Arquiteturais <br />

4. [Modelagem](#modelagem "Modelagem e projeto arquitetural") <br />
	4.1. Visão de Negócio <br />
	4.2. Visão Lógica <br />
	4.3. Modelo de dados (opcional) <br />

5. [Wireframes](#wireframes "Wireframes") <br />

6. [Solução](#solucao "Projeto da Solução") <br />

7. [Avaliação](#avaliacao "Avaliação da Arquitetura") <br />
	7.1. Cenários <br />
	7.2. Avaliação <br />

8. [Referências](#referencias "REFERÊNCIAS")<br />

9. [Apêndices](#apendices "APÊNDICES")<br />
	9.1 Ferramentas <br />


<a name="apresentacao"></a>
# 1. Apresentação
Atualmente, no contexto de desenvolvimento e execução de projetos, existe uma grande vertente, que é a aplicação de metodos agéis nos projetos, principalmente o SCRUM, que é um exemplo destas metodologias, estes metodos prometem trazer mais rapidez no desenvolvimento do produto, com um foco mais nas entregas e na relaçao da equipe com o cliente, do que em documentação, e outras coisas que podem "freiar" o desenvolvimento. Focando mais na relação entre os membros da equipe, estas metodologias se concentram em como a equipe trabalha, e a partir das entregas incrementais, onde o produto e desenvolvido sprint após sprint.

​As metodologias ágeis, incluindo o Scrum, têm ganhado ampla adoção no ambiente corporativo global, destacando-se especialmente em áreas de tecnologia da informação. Um estudo realizado pela NTT Data em conjunto com o MIT Technology Review revelou que 90% das organizações latino-americanas afirmam que suas áreas de TI e/ou desenvolvimento adotam metodologias ágeis. Além disso, 48% das áreas de dados e analytics também incorporam essa abordagem


## 1.1. Problema
No entanto, eles tambem possuem suas fragilidades, podemos dizer que a principal delas é a execução mal feita destas metodologias, o que pode acarretar em atrasos e uma redução na dinamização do trabalho. Estas praticas danosas são inumeras, e podem ser exemplificadas como, execução errada dos ritos SCRUM, divisão e interpretação inadequada dos papéis nas equipes, entre outros. Podemos dizer que a maioria dos problemas operacionais relacionados a estas metodologias, provem da maneira que a mesma é aplicada no contexto das empresas.

Gargalos de desempenho também podem ser observados, eles provem de um mapeamento ruim do desempenho dos membros da equipe, onde não se sabe ao certo o que e como cada membro esta produzindo, e podem resultar em atrasos, dividas técnicas, entregas rejeitadas, entre outros.

## 1.2. Objetivos do trabalho

O Chronos é uma solução que promete reduzir ao maximo estas praticas equivocadas, oferecendo um ambiente onde os papéis dos membros são claramente evidenciados e diferenciados, onde os ritos poderão ser cadastrados e gerenciados com precisão e da maneira correta. Uma outra solução ofertada pelo Chronos são as métricas de desempenho que o mesmo oferece para o gestor da equipe, onde o mesmo pode visualizar tempo gasto nas tasks, uma avaliação da entrega das mesmas, entre outras métricas, que podem fazer com que gargalos de desempenho e alocação de tarefas possam ser especificados e corrigidos.

## 1.3. Definições e Abreviaturas
Sprint: Um ciclo de trabalho com duração fixa (geralmente entre 1 e 4 semanas) em que um incremento do produto é desenvolvido, revisado e entregue.

Product Backlog: Uma lista ordenada de funcionalidades, melhorias e correções que devem ser implementadas no produto. É gerenciada pelo Product Owner.

Sprint Backlog: Um subconjunto do Product Backlog, contendo as tarefas que a equipe de desenvolvimento se compromete a realizar durante o Sprint.

Incremento: A soma de todos os itens do Product Backlog completados durante um Sprint e as Sprints anteriores, que resultam em um incremento funcional do produto.

Daily Stand-up (Daily Scrum): Reunião diária, geralmente de 15 minutos, onde os membros da equipe discutem o progresso, os obstáculos e as tarefas do dia.

Retrospective: Reunião realizada no final de cada Sprint onde a equipe reflete sobre o processo de trabalho, identifica pontos de melhoria e propõe ajustes para o próximo Sprint.

Sprint Review: Reunião realizada no final de cada Sprint para revisar o trabalho realizado, obter feedback das partes interessadas e ajustar o Product Backlog conforme necessário.

Definition of Done (DoD): Critérios claros que definem quando uma tarefa, história ou incremento de trabalho está completo e pronto para ser considerado entregue.

Product Owner (PO): Pessoa responsável por definir as funcionalidades do produto, gerenciar o Product Backlog e garantir que as necessidades do cliente sejam atendidas.

Scrum Master: Facilitador do processo Scrum, responsável por remover obstáculos e garantir que a equipe siga as práticas e valores do Scrum.

Development Team: Equipe multifuncional responsável pela execução das tarefas, desenvolvimento do produto e entrega do incremento.

Stakeholders: Partes interessadas no projeto que têm interesse nos resultados e nos entregáveis do produto.

User Stories (Histórias de Usuário): Descrições curtas e simples de uma funcionalidade do sistema, do ponto de vista do usuário final.

<a name="produto"></a>
# 2. Nosso Produto

_Estão seçaõ explora um pouco mais o produto a ser desenvolvido_

## 2.1 Visão do Produto

O projeto Chronos consiste em um sistema de gerenciamento de projetos voltado para equipes ágeis, acessível tanto em plataformas web quanto mobile, que busca otimizar a organização, o monitoramento e a comunicação dentro de times que utilizam metodologias como Scrum e Kanban. Ele oferece uma dashboard para visualização de desempenho, quadros visuais para acompanhamento de tarefas, gráficos de progresso e a possibilidade de gerenciar múltiplos projetos simultaneamente, com funcionalidades que permitem ao Scrum Master coordenar reuniões e equipes, enquanto Product Owners administram tarefas e gestores avaliam profissionais com base em métricas. Além disso, o sistema automatiza processos como aprovação de entregas, avaliação de desempenho, notificações de prazos e comunicação entre membros, promovendo eficiência e colaboração em um ambiente dinâmico e integrado.

## 2.2 Nosso Produto

O aplicativo Chronos é uma solução de gerenciamento de projetos voltada para equipes ágeis, acessível tanto em plataformas web quanto mobile, projetada para otimizar a organização e o acompanhamento de tarefas. **É** um app multiplataforma, gratuito e fácil de usar, que oferece uma dashboard para visualização de desempenho, quadros Kanban e gráficos Burndown, permitindo ao Scrum Master gerenciar reuniões e equipes, enquanto Product Owners administram tarefas e gestores avaliam profissionais com base em métricas. **Faz** a gestão de múltiplos projetos simultaneamente, automatiza a aprovação e avaliação de entregas, notifica usuários sobre prazos e atualizações, calcula a média de tempo gasto em tarefas e promove comunicação eficiente entre membros com mensagens automáticas. **Não é** uma rede social como Facebook, Twitter ou WhatsApp, nem um site ou um messenger focado em chat, mas sim uma ferramenta de produtividade. **Não faz** a organização de jogos ou times, não cria campeonatos, não define tempos por ordem de pedido, não gerencia pagamentos de pelada online e não organiza jogos privados, sendo seu foco estritamente voltado para a gestão de projetos e equipes de trabalho. Com isso, o Chronos se posiciona como um aliado essencial para equipes que buscam eficiência e colaboração em seus processos.

## 2.3 Personas
<h2>Persona 1</h2>
<table> <tr> <td style="vertical-align: top; width: 150px;"> <img src="imagens/persona1.jpg" alt="Imagem da Persona 1" style="width: 100px; height: auto; border-radius: 10px;"> </td> <td style="vertical-align: top; padding-left: 10px;"> <strong>Nome:</strong> Ana Clara Souza <br> <strong>Idade:</strong> 34 anos <br> <strong>Hobby:</strong> Ler livros de ficção científica e praticar yoga <br> <strong>Trabalho:</strong> Scrum Master em uma empresa de tecnologia <br> <strong>Personalidade:</strong> Organizada, proativa e focada em resultados <br> <strong>Sonho:</strong> Tornar-se uma referência em gestão ágil no Brasil <br> <strong>Dores:</strong> Falta de ferramentas que centralizem a gestão de reuniões e permitam comunicação eficiente com a equipe, além de dificuldade em acompanhar o progresso de múltiplos projetos simultaneamente <br> </td> </tr> </table>

<h2>Persona 2</h2>

<table> <tr> <td style="vertical-align: top; width: 150px;"> <img src="imagens/persona2.jpg" alt="Imagem da Persona 2" style="width: 100px; height: auto; border-radius: 10px;"> </td> <td style="vertical-align: top; padding-left: 10px;"> <strong>Nome:</strong> Rafael Lima <br> <strong>Idade:</strong> 41 anos <br> <strong>Hobby:</strong> Tocar violão e assistir a documentários sobre inovação <br> <strong>Trabalho:</strong> Product Owner em uma startup de software <br> <strong>Personalidade:</strong> Analítico, detalhista e orientado a prazos <br> <strong>Sonho:</strong> Lançar um produto revolucionário que impacte milhões de usuários <br> <strong>Dores:</strong> Dificuldade em gerenciar tarefas de forma eficiente e garantir que as entregas sejam aprovadas no prazo, além de precisar de mais visibilidade sobre o tempo médio gasto nas tarefas <br> </td> </tr> </table>

<h2>Persona 3</h2>

<table> <tr> <td style="vertical-align: top; width: 150px;"> <img src="imagens/persona3.jpg" alt="Imagem da Persona 3" style="width: 100px; height: auto; border-radius: 10px;"> </td> <td style="vertical-align: top; padding-left: 10px;"> <strong>Nome:</strong> Mariana Costa <br> <strong>Idade:</strong> 38 anos <br> <strong>Hobby:</strong> Cozinhar receitas internacionais e fazer trilhas <br> <strong>Trabalho:</strong> Gestora de projetos em uma consultoria de TI <br> <strong>Personalidade:</strong> Estratégica, exigente e focada em desempenho <br> <strong>Sonho:</strong> Construir uma equipe de alta performance reconhecida no mercado <br> <strong>Dores:</strong> Falta de métricas claras para avaliar o desempenho da equipe e dificuldade em identificar os melhores profissionais para alocar em projetos estratégicos <br> </td> </tr> </table>


<a name="requisitos"></a>
# 3. Requisitos

_Esta seção descreve os requisitos comtemplados nesta descrição arquitetural, divididos em dois grupos: funcionais e não funcionais._

## 3.1. Requisitos Funcionais


| **ID** | **Descrição** | **Prioridade** | **Plataforma** | **Sprint** | **Status** |
| --- | --- | --- | --- | --- | --- |
| RF001 | O sistema deverá possuir uma dashboard mostrando dados de desempenho da equipe/membro  |  Desejável  | _web_ |  | ❌ |
| RF002 | O sistema edverá enviar notifições em caso de atualizações em itens relacionados ao usuário  |  Essencial  | _web e mobile_ |  | ✔ |
| RF003 | O Scrum Master poderá gerenciar reuniões  |  Essencial  | _web_ |  | ✔ |
| RF004 | O sistema deverá possuir um quadro KanBan  |  Essencial  | _web e mobile_ |  | ✔ |
| RF005 | O sistema podera permitir a gerencia de 1 ou mais projetos simultaneamente  |  Desejável  | _web e mobile_ |  | ✔ |
| RF006 | O sistema deverá possuir um grafico Burndown  |  Opcional  | _web e mobile_ |  | ✔ |
| RF007 | Tarefas entregues deverão ser aprovadas por membros responsáveis  |  Essencial  | _web e mobile_ |  | ✔ |
| RF008 | O sistema deverá possuir um ranking de complexidade nas tarefas alocadas  |  Desejável  | _web e mobile_ |  | ✔ |
| RF009 | O sistema deverá informar a média de tempo gasto pelo usuario na execução das tarefas  |  Essencial  | _web e mobile_ |  | ❌ |
| RF010 | O sistema deverá notificar o usuário em casos de aproximação da data limite das tarefas |  Essencial  | _web e mobile_ |  | ✔ |
| RF011 | Usuarios com permissões de Scrum Master, poderão gerenciar os membros da equipe do projeto  |  Essencial  | _web_ |  | ✔ |
| RF012 | Usuarios com permissões de Scrum Master, poderão criar notificações personalizadas, e envia-las para todos os membros da equipe  |  Opcional  | _web_ |  | ❌ | (negociar)
| RF013 | O sistema deverá avaliar as entregas, e atribuir notas para as mesmas automaticamente  |  Essencial  | _web_ |  | ❌ |
| RF014 | Usuario com permissões de P.O poderão gerenciar as tasks do projeto  |  Essencial  | _web e mobile_ |  | ✔ |
| RF015 | O sistema deverá prover ao Gestor do projeto um score de melhores profissionais para cada tarefa baseando-se em métricas de desempenho |  Essencial  | _web_ |  | ✔ |
| RF015 | Após a conclusão de uma tarefa, o sistema devera enviar mensagens de aviso aos usuarios com tarefas relacionadas a recem concluida |  Desejável  | _web e mobile_ |  | ❌ | (negociar)

## 3.2. Requisitos Não-Funcionais

| **ID** | **Descrição** |
| --- | --- |
| RNF001 | O sistema deve ser capaz de processar e exibir métricas e relatórios em até 3 segundos para 95% das requisições realizadas. |
| RNF002 | O sistema deve ser capaz de suportar o aumento progressivo de dados e usuários sem degradação perceptível de desempenho, podendo escalar horizontalmente para comportar mais acessos simultâneos. |
| RNF003 | O sistema deve garantir que apenas usuários autenticados e autorizados possam acessar funcionalidades específicas (gestores, membros da equipe, etc.). |
| RNF004 | Todos os dados sensíveis, como informações de login e métricas de desempenho, devem ser criptografados |
| RNF005 | O software deve ser acessível para usuários com necessidades especiais, incluindo suporte a leitores de tela e navegação por teclado. |
| RNF006 | O sistema deve garantir uma disponibilidade mínima de 99,9%, com tempo de inatividade planejado limitado a 1 hora por mês. |
| RNF007 | O sistema deve ser responsivo e funcional em uma ampla gama de dispositivos (desktop, tablets e smartphones) e compatível com navegadores modernos. |
| RNF008 | O tempo de carregamento da interface do usuário deve ser de no máximo 2 segundos em 95% dos acessos.  |
| RNF009 | O sistema deve ser altamente testável, com cobertura de testes unitários, testes de integração e testes de ponta a ponta cobrindo pelo menos 80% do código. |


## 3.3. Restrições Arquiteturais

_As restrições impostas ao projeto que afetam sua arquitetura são:_

- O software deverá ser desenvolvido utilizando o Flutter para a construção da interface de usuário (front-end).
- O back-end deverá ser desenvolvido utilizando o framework Nest.js em Node.js, com suporte para TypeScript.
- A comunicação da API deverá seguir o padrão RESTful, garantindo que todas as interações entre o front-end e o back-end sejam realizadas via requisições HTTP com endpoints bem definidos.
- O sistema deverá utilizar um ORM para comunicação com o banco de dados, sendo o Prisma a tecnologia escolhida para o mapeamento objeto-relacional (ORM) no back-end.
- O banco de dados deverá ser baseado em não-relacional (NoSQL).
- O sistema deverá ser hospedado em uma plataforma cloud
- A autenticação e autorização do sistema deverão ser baseadas em OAuth 2.0 para garantir segurança no acesso à aplicação.

## 3.4. Mecanismos Arquiteturais

_Visão geral dos mecanismos que compõem a arquitetura do sosftware baseando-se em três estados: (1) análise, (2) design e (3) implementação. Em termos de Análise devem ser listados os aspectos gerais que compõem a arquitetura do software como: persistência, integração com sistemas legados, geração de logs do sistema, ambiente de front end, tratamento de exceções, formato dos testes, formato de distribuição/implantação (deploy), entre outros. Em Design deve-se identificar o padrão tecnológico a seguir para cada mecanismo identificado na análise. Em Implementação, deve-se identificar o produto a ser utilizado na solução._

| **Análise** | **Design** | **Implementação** |
| --- | --- | --- |
| Persistência | ORM | Prisma |
| Front end | Framework | Flutter |
| Back end | Framework  | Nest.js |
| Integração | API Rest | Fastfy |
| Log do sistema | ELK | ELK Stack |
| Teste de Software | TDD | Jest |
| Deploy | Nuvem | AWS |
| Segurança | Autenticação e Autorização | Auth0 |
| Armazenamento de Dados | Banco de Dados | MongoDB |

<a name="modelagem"></a>
# 4. Modelagem e Projeto Arquitetural

_Apresente uma visão geral da solução proposta para o projeto e explique brevemente esse diagrama de visão geral, de forma textual. Esse diagrama não precisa seguir os padrões da UML, e deve ser completo e tão simples quanto possível, apresentando a macroarquitetura da solução._

![Visão Geral da Solução](imagens/visao.png "Visão Geral da Solução")

**Figura 1 - Visão Geral da Solução (fonte: https://medium.com)**

Obs: substitua esta imagem por outra, adequada ao seu projeto (cada arquitetura é única).

## 4.1. Visão de Negócio (Funcionalidades)

_Apresente uma lista simples com as funcionalidades previstas no projeto (escopo do produto)._

1. O sistema deve...
2. O sistema deve...
3. ...

Obs: a quantidade e o escopo das funcionalidades deve ser negociado com os professores/orientadores do trabalho.

### Histórias de Usuário

_Nesta seção, você deve descrever estórias de usuários seguindo os métodos ágeis. Lembre-se das características de qualidade das estórias de usuários, ou seja, o que é preciso para descrever boas histórias de usuários._

Exemplos de Histórias de Usuário:

- Como Fulano eu quero poder convidar meus amigos para que a gente possa se reunir...

- Como Cicrano eu quero poder organizar minhas tarefas diárias, para que...

- Como gerente eu quero conseguir entender o progresso do trabalho do meu time, para que eu possa ter relatórios periódicos dos nossos acertos e falhas.

|EU COMO... `PERSONA`| QUERO/PRECISO ... `FUNCIONALIDADE` |PARA ... `MOTIVO/VALOR`                 |
|--------------------|------------------------------------|----------------------------------------|
|Usuário do sistema  | Registrar minhas tarefas           | Não esquecer de fazê-las               |
|Administrador       | Alterar permissões                 | Permitir que possam administrar contas |

## 4.2. Visão Lógica

_Apresente os artefatos que serão utilizados descrevendo em linhas gerais as motivações que levaram a equipe a utilizar estes diagramas._

### Diagrama de Classes

![Diagrama de classes](imagens/classes.gif "Diagrama de classes")


**Figura 2 – Diagrama de classes (exemplo). Fonte: o próprio autor.**

Obs: Acrescente uma breve descrição sobre o diagrama apresentado na Figura 3.

### Diagrama de componentes

_Apresente o diagrama de componentes da aplicação, indicando, os elementos da arquitetura e as interfaces entre eles. Liste os estilos/padrões arquiteturais utilizados e faça uma descrição sucinta dos componentes indicando o papel de cada um deles dentro da arquitetura/estilo/padrão arquitetural. Indique também quais componentes serão reutilizados (navegadores, SGBDs, middlewares, etc), quais componentes serão adquiridos por serem proprietários e quais componentes precisam ser desenvolvidos._

![Diagrama de componentes](imagens/componentes.png "Diagrama de componentes")

**Figura 3 – Diagrama de Componentes (exemplo). Fonte: o próprio autor.**

_Apresente uma descrição detalhada dos artefatos que constituem o diagrama de implantação._

Ex: conforme diagrama apresentado na Figura X, as entidades participantes da solução são:

- **Componente 1** - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras nunc magna, accumsan eget porta a, tincidunt sed mauris. Suspendisse orci nulla, sagittis a lorem laoreet, tincidunt imperdiet ipsum. Morbi malesuada pretium suscipit.
- **Componente 2** - Praesent nec nisi hendrerit, ullamcorper tortor non, rutrum sem. In non lectus tortor. Nulla vel tincidunt eros.

## 4.3. Modelo de dados (opcional)

_Caso julgue necessário para explicar a arquitetura, apresente o diagrama de classes ou diagrama de Entidade/Relacionamentos ou tabelas do banco de dados. Este modelo pode ser essencial caso a arquitetura utilize uma solução de banco de dados distribuídos ou um banco NoSQL._

![Diagrama de Entidade Relacionamento (ER) ](imagens/der.png "Diagrama de Entidade Relacionamento (ER) ")

**Figura 4 – Diagrama de Entidade Relacionamento (ER) - exemplo. Fonte: o próprio autor.**

Obs: Acrescente uma breve descrição sobre o diagrama apresentado na Figura 3.

<a name="wireframes"></a>
# 5. Wireframes

> Wireframes são protótipos das telas da aplicação usados em design de interface para sugerir a
> estrutura de um site web e seu relacionamentos entre suas
> páginas. Um wireframe web é uma ilustração semelhante ao
> layout de elementos fundamentais na interface.

<a name="solucao"></a>
# 6. Projeto da Solução

_Apresente as telas dos sistema construído com uma descrição sucinta de cada uma das interfaces._

<a name="avaliacao"></a>
# 7. Avaliação da Arquitetura

_Esta seção descreve a avaliação da arquitetura apresentada, baseada no método ATAM._

## 7.1. Cenários

_Apresente os cenários de testes utilizados na realização dos testes da sua aplicação. Escolha cenários de testes que demonstrem os requisitos não funcionais sendo satisfeitos. Os requisitos a seguir são apenas exemplos de possíveis requisitos, devendo ser revistos, adequados a cada projeto e complementados de forma a terem uma especificação completa e auto-explicativa._

**Cenário 1 - Acessibilidade:** Suspendisse consequat consectetur velit. Sed sem risus, dictum dictum facilisis vitae, commodo quis leo. Vivamus nulla sem, cursus a mollis quis, interdum at nulla. Nullam dictum congue mauris. Praesent nec nisi hendrerit, ullamcorper tortor non, rutrum sem. In non lectus tortor. Nulla vel tincidunt eros.

**Cenário 2 - Interoperabilidade:** Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Fusce ut accumsan erat. Pellentesque in enim tempus, iaculis sem in, semper arcu.

**Cenário 3 - Manutenibilidade:** Phasellus magna tellus, consectetur quis scelerisque eget, ultricies eu ligula. Sed rhoncus fermentum nisi, a ullamcorper leo fringilla id. Nulla lacinia sem vel magna ornare, non tincidunt ipsum rhoncus. Nam euismod semper ante id tristique. Mauris vel elit augue.

**Cenário 4 - Segurança:** Suspendisse consectetur porta tortor non convallis. Sed lobortis erat sed dignissim dignissim. Nunc eleifend elit et aliquet imperdiet. Ut eu quam at lacus tincidunt fringilla eget maximus metus. Praesent finibus, sapien eget molestie porta, neque turpis congue risus, vel porttitor sapien tortor ac nulla. Aliquam erat volutpat.

## 7.2. Avaliação

_Apresente as medidas registradas na coleta de dados. O que não for possível quantificar apresente uma justificativa baseada em evidências qualitativas que suportam o atendimento do requisito não-funcional. Apresente uma avaliação geral da arquitetura indicando os pontos fortes e as limitações da arquitetura proposta._

| **Atributo de Qualidade:** | Segurança |
| --- | --- |
| **Requisito de Qualidade** | Acesso aos recursos restritos deve ser controlado |
| **Preocupação:** | Os acessos de usuários devem ser controlados de forma que cada um tenha acesso apenas aos recursos condizentes as suas credenciais. |
| **Cenários(s):** | Cenário 4 |
| **Ambiente:** | Sistema em operação normal |
| **Estímulo:** | Acesso do administrador do sistema as funcionalidades de cadastro de novos produtos e exclusão de produtos. |
| **Mecanismo:** | O servidor de aplicação (Rails) gera um _token_ de acesso para o usuário que se autentica no sistema. Este _token_ é transferido para a camada de visualização (Angular) após a autenticação e o tratamento visual das funcionalidades podem ser tratados neste nível. |
| **Medida de Resposta:** | As áreas restritas do sistema devem ser disponibilizadas apenas quando há o acesso de usuários credenciados. |

**Considerações sobre a arquitetura:**

| **Riscos:** | Não existe |
| --- | --- |
| **Pontos de Sensibilidade:** | Não existe |
| _ **Tradeoff** _ **:** | Não existe |

Evidências dos testes realizados

_Apresente imagens, descreva os testes de tal forma que se comprove a realização da avaliação._

<a name="referencias"></a>
# 8. REFERÊNCIAS

_Como um projeto da arquitetura de uma aplicação não requer revisão bibliográfica, a inclusão das referências não é obrigatória. No entanto, caso você deseje incluir referências relacionadas às tecnologias, padrões, ou metodologias que serão usadas no seu trabalho, relacione-as de acordo com a ABNT._

Verifique no link abaixo como devem ser as referências no padrão ABNT:

http://www.pucminas.br/imagedb/documento/DOC\_DSC\_NOME\_ARQUI20160217102425.pdf


**[1]** - _ELMASRI, Ramez; NAVATHE, Sham. **Sistemas de banco de dados**. 7. ed. São Paulo: Pearson, c2019. E-book. ISBN 9788543025001._

**[2]** - _COPPIN, Ben. **Inteligência artificial**. Rio de Janeiro, RJ: LTC, c2010. E-book. ISBN 978-85-216-2936-8._

**[3]** - _CORMEN, Thomas H. et al. **Algoritmos: teoria e prática**. Rio de Janeiro, RJ: Elsevier, Campus, c2012. xvi, 926 p. ISBN 9788535236996._

**[4]** - _SUTHERLAND, Jeffrey Victor. **Scrum: a arte de fazer o dobro do trabalho na metade do tempo**. 2. ed. rev. São Paulo, SP: Leya, 2016. 236, [4] p. ISBN 9788544104514._

**[5]** - _RUSSELL, Stuart J.; NORVIG, Peter. **Inteligência artificial**. Rio de Janeiro: Elsevier, c2013. xxi, 988 p. ISBN 9788535237016._


<a name="apendices"></a>
# 9. APÊNDICES

_Inclua o URL do repositório (Github, Bitbucket, etc) onde você armazenou o código da sua prova de conceito/protótipo arquitetural da aplicação como anexos. A inclusão da URL desse repositório de código servirá como base para garantir a autenticidade dos trabalhos._

## 9.1 Ferramentas

| Ambiente  | Plataforma              |Link de Acesso |
|-----------|-------------------------|---------------|
|Repositório de código | GitHub | https://github.com/XXXXXXX | 
|Hospedagem do site | Heroku |  https://XXXXXXX.herokuapp.com | 
|Protótipo Interativo | MavelApp ou Figma | https://figma.com/XXXXXXX |
|Documentação de teste | Github | https://githun.com/xxxx |
