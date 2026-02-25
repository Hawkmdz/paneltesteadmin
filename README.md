# BoostPanel

Plataforma SMM para turbinar redes sociais.

## Stack

- HTML + CSS + JS puro (single-file app)
- Supabase (auth + banco de dados)
- Vercel (hospedagem)

## Deploy

### 1. Git

```bash
git init
git add .
git commit -m "first commit"
git remote add origin https://github.com/SEU_USER/boostpanel.git
git push -u origin main
```

### 2. Vercel (via CLI)

```bash
npm i -g vercel
vercel --prod
```

### 3. Vercel (via dashboard)

1. Acesse [vercel.com](https://vercel.com)
2. "New Project" → importe o repositório do GitHub
3. Clique em **Deploy** — sem configuração adicional necessária

## Variáveis de Ambiente

Nenhuma variável de ambiente é necessária. As credenciais do Supabase são configuradas diretamente pelo painel admin em **Configurações → Integração de API**.

## Acesso Admin

O acesso admin é feito pelo mesmo formulário de login da área do cliente. Usuários com `role = 'admin'` no banco são redirecionados automaticamente para o painel administrativo.

Para promover um usuário a admin no Supabase:

```sql
UPDATE public.profiles SET role = 'admin' WHERE email = 'seu@email.com';
```
