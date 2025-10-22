# Atividade Prática 2

(adicione aqui um resumo da atividade prática 2)

## Dupla 5

- Daniel Garcia Boer (25105144)
- Filipe Potrich Cechim (25100483)


## Descrição

(Descrição da atividade prática 2 (AP2). Inclua aqui a descrição do circuito entregue. )

Se você quiser, pode adicionar algum de trecho de código VHDL que aches relevante. 
Em `markdown` isso pode ser feito como no exemplo abaixo

```vhdl
ARCHITECTURE arch OF registrador IS
--- implementar
BEGIN
END arch;
```

> Notem que não é necessário adicionar todo o código VHDL de vocês aqui, isso é apenas um exemplo do que vocês podem adicionar ao relatório e de como vocês podem formatar em `markdown`.

O circuito desenvolvido implementa o cálculo da **Soma das Diferenças Absolutas (SAD – *Sum of Absolute Differences*)**, operação amplamente utilizada em sistemas de **processamento digital de sinais** e **visão computacional**, especialmente em algoritmos de **correlação de blocos** e **compressão de vídeo**.  

O objetivo do circuito é calcular a soma das diferenças absolutas entre dois conjuntos de valores (por exemplo, intensidades de pixels em blocos de imagem), de forma **modular e síncrona**, utilizando componentes básicos projetados em **VHDL**.  

---

### Estrutura

O cálculo da SAD é descrito por

\[
SAD = \sum_i |A_i - B_i|
\]

O sistema foi dividido em módulos independentes, facilitando o entendimento, a simulação e a reutilização dos componentes.  
Os principais blocos que compõem o projeto e as seções de código mais representativas de suas funções são:

- `absolute_difference.vhdl` — responsável por calcular o valor absoluto da diferença entre dois sinais -> cálculo representado principalmente pela descrição a seguir;
```vhdl
ARCHITECTURE structure OF absolute_difference IS
--- ... declarações de sinais com tamanhos genéricos
BEGIN
    -- Calcula as duas direcoes da subtracao concorrentemente
    diff_a_minus_b <= input_a - input_b; -- (A - B)
    diff_b_minus_a <= input_b - input_a; -- (B - A)

    -- O sinal de selecao escolhe o resultado positivo (nao-overflow)
    -- '1' seleciona (A - B) se A >= B
    -- '0' seleciona (B - A) se A < B
    select_mux <= '1' when input_a >= input_b else '0';
--- ... (instancia do mux e output da diferença absoluta)
END structure;
```
- `signed_subtractor.vhdl` — realiza a subtração entre números com sinal -> aqui, destaca-se a subtração entre números com sinal, ou seja, do tipo signed, a qual é diferenciada da anterior por esse único motivo; 
- `unsigned_adder.vhdl` — efetua a soma de valores inteiros sem sinal -> utilizado no bloco operativo da SAD (sad_bo) para mapear os valores retornados da diferença absoluta para suas entradas de soma, compreendendo a soma iterativa das diferenças como explicitado pela seguinte expressão e código:


  
- `mux_2to1.vhdl` — seleciona entre duas entradas com base em um sinal de controle;  
- `unsigned_register.vhdl` — armazena valores intermediários de forma síncrona com o clock;  
- `sad_pack.vhdl` — contém tipos e constantes auxiliares utilizados nos módulos principais. Um exemplo a seguir é a declaração da função sad_length em sad_pack, que é utilizada posteriormente em sad_bo (seção de código mostrada após a primeira);  
```
--- sad_pack
    function sad_length(bits_per_sample : positive; samples_per_block : positive) return positive;
```
--
```
--- sad_bo
    constant SAD_WIDTH  : positive := sad_length(CFG.bits_per_sample, CFG.samples_per_block);
```
- `sad_bc.vhdl` e `sad_bo.vhdl` — blocos intermediários de controle e operação do SAD, responsáveis pela organização das entradas e pela soma acumulada;  
- `sad.vhdl` — módulo principal, que integra os componentes anteriores e implementa a lógica completa da soma das diferenças absolutas.  

A arquitetura modular permite que o circuito seja facilmente testado e expandido, mantendo a coerência funcional entre os módulos.

### Simulação

A validação funcional e a depuração da arquitetura SAD v1 foram realizadas primariamente durante a Atividade Prática 1 (AP1), utilizando o ambiente de testes e simulação do **VPL**. Os testes no VPL cobriram diversos casos de uso e combinações de entrada, confirmando que a lógica do circuito estava funcionalmente correta antes da etapa de síntese.

Para esta Atividade Prática 2 (AP2), após a síntese bem-sucedida do projeto no Quartus II, foi realizada uma simulação adicional do tipo **"Gate Level Simulation"**. Esta simulação foi executada utilizando a ferramenta **ModelSim-Altera**, iniciada a partir do próprio Quartus. Este método permite a inclusão dos atrasos reais de portas e interconexões calculados durante a síntese (utilizando o arquivo `.sdo` gerado).

Para esta simulação, foi criado um script de estímulos (`estimulos.do`) que reseta o circuito, aplica valores de entrada (`sample_ori` = 10 e `sample_can` = 5) e habilita o início do cálculo.

O resultado da simulação (imagem abaixo) confirma o comportamento esperado da máquina de estados síncrona:

- O circuito responde corretamente ao sinal de reset (`rst_a`).
    
- Após o `enable`, os sinais de saída `address` e `read_mem` mostram que o circuito está iterando automaticamente pelos endereços de memória para realizar o cálculo do SAD, validando a lógica de controle pós-síntese.

![[ModelSim-Altera.png]]

Exemplo de tabela em markdown (pode ser útil para descrição dos estímulos testados):

|  A  |  B  |  S  |
| :-: | :-: | :-: |
|  0  |  0  |  0  |
|  0  |  1  |  1  |
|  1  |  0  |  1  |
|  1  |  1  |  0  |

Também é possível incluir imagens em `markdown`. Procurem saber mais sobre a linguagem, ela será útil para vocês para além desta disciplina!

> Busquem por um visualizador (renderizador) de `markdown`. Vai ajudar vocês a endenderem melhor sobre a linguagem.



## Outras observações

Aqui vocês podem comentar qualquer observação que vocês gostariam de levantar sobre os circuitos descritos, dificuldades gerais, etc.

Também podem adicionar se fizeram a implementação para a SAD v3. 
