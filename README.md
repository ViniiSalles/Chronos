# Chronos

Plataforma web e mobile de gestão ágil de projetos e tarefas, pensada para equipes que trabalham com Scrum e Kanban. Reúne projetos, tarefas com avaliação, quadros Kanban, reuniões e notificações em um só lugar, com a proposta de usar elementos de gamificação para aumentar o engajamento do time.

Projeto acadêmico desenvolvido no curso de Engenharia de Software da PUC Minas (1º semestre de 2025).

<!-- Adicione aqui 2 ou 3 prints das principais telas (login, lista de projetos, quadro Kanban) -->

## Funcionalidades

- Cadastro e autenticação de usuários (e-mail e senha)
- Criação de projetos e gestão das equipes de cada projeto
- Tarefas com responsáveis, relacionamentos entre tarefas, conclusão e avaliação
- Quadros Kanban com colunas configuráveis
- Agendamento de reuniões
- Notificações para os usuários

## Arquitetura e tecnologias

| Camada | Tecnologia |
| --- | --- |
| Front-end (web e mobile) | Flutter |
| Back-end | NestJS + TypeScript (API REST) |
| Banco de dados | MongoDB (Mongoose) |
| Autenticação | Firebase Authentication no app, com validação de token no back-end |
| Mensageria | Apache Kafka (produtor e consumidor) |
| Deploy do back-end | Docker + Fly.io |

O back-end é organizado em módulos NestJS (`user`, `project`, `task`, `kanban`, `meetings`, `notifications`, `kafka`) e as rotas protegidas passam por um guard que valida o token do Firebase. A documentação de arquitetura está em [`docs/architecture_document.md`](docs/architecture_document.md).

## Como rodar

### Back-end

```sh
cd code/backend
yarn install
yarn start:dev
```

Crie um arquivo `code/backend/.env` com as variáveis abaixo (não versione esse arquivo):

```
PORT=3000
MONGODB_URI=
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
```

Testes: `yarn test`.

### Front-end

```sh
cd code
flutter pub get
flutter run
```

## Equipe

- Alfredo Luis Vieira
- Bruno Evangelista Gomes de Azevedo
- David Dias Pinto
- Vinicius Salles de Oliveira: telas em Flutter, autenticação e back-end

Professores orientadores: Leonardo Vilela Cardoso e Artur Martins Mol.
