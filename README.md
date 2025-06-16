🧼 Limpeza de Disco em Servidores Windows

Este projeto tem como objetivo automatizar o processo de *limpeza do disco C:* em servidores Windows, removendo arquivos temporários, logs antigos, caches e outros itens obsoletos. A automação visa reduzir incidentes por falta de espaço, otimizar a performance dos servidores e oferecer visibilidade através de dashboards no Power BI.

---
⚙️ Tecnologias Utilizadas

PowerShell – Automação da limpeza de disco e geração de relatórios;

CSV – Exportação dos resultados da limpeza por servidor;

Power BI – Visualização dos dados e indicadores de espaço recuperado.


🚀 Como utilizar

1. Configure o script PowerShell
Ajuste os caminhos e parâmetros de acordo com a realidade do seu ambiente (pastas temporárias, perfis, logs etc.).


2. Agende a execução
Recomenda-se executar o script semanalmente via Agendador de Tarefas do Windows ou SCCM.


3. Coleta de dados
Use a saída CSV para armazenar os dados em um repositório central (pasta de rede, banco ou API).


4. Dashboards Power BI
Conecte o Power BI ao(s) CSV(s) gerado(s) e utilize o arquivo .pbix como exemplo para montar seu painel de indicadores.


---

📊 Métricas e Indicadores Sugeridos

Espaço Livre Antes e Depois (por servidor e por mês)

Total de Espaço Recuperado

% de Espaço Recuperado

Distribuição por Versão de Sistema Operacional

Tendência Mensal de Limpeza



---

✅ Benefícios

Menos incidentes por disco cheio

Melhoria de performance em servidores legados

Governança e visibilidade com métricas claras

Reutilizável e adaptável a diferentes ambientes

