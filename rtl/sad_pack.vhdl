--------------------------------------------------
--	Author:      Ismael Seidel (entity)
--	Created:     May 1, 2025
--
--	Project:     Exerc�cio 6 de INE5406
--	Description: Este pacote cont�m defini��es de tipos e fun��es auxiliares que
--               podem ser utilizadas no circuito para c�lculo da soma das diferen�as
--               absolutas (SAD - Sum of Absolute Differences). 
--               Aten��o: Voc� pode incluir novos tipos e fun��es neste arquivo.
--                        Por�m, n�o altere os tipos e fun��es j� existentes, pois
--                        alguns testes podem ser utilizados na avalia��o (tesbenches).
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package sad_pack is
    -- Declara��o do tipo parallel_samples_vector. 
    -- Note que � um array que n�o tem tamanho especificado de unsigned, que por sua vez tamb�m
    -- � um array sem tamanho especificado. Assim, na declara��o de um parallel_samples_vector �
    -- necess�rio especificar duas dimens�es, uma para o n�mero de elementos unsigned em paralelo 
    -- e outra para o n�mero de elementos em unsigned. Por exemplo:
    -- signal oito_de_dez_bits_em_paralelo : parallel_samples_vector(0 to 7)(9 downto 0);
    

    -- Fun��o para convers�o de std_logic_vector para parallel_samples_vector.
    -- Essa fun��o auxiliar divide um std_logic_vector de comprimento PxN em P amostras de N 
    -- bits. Cada amostra � representada como um unsigned (veja a defini��o do tipo 
    -- parallel_samples_vector).
    

    -- Fun��o para convers�o de parallel_samples_vector para std_logic_vector.
    -- Essa fun��o realiza a opera��o inversa da fun��o anterior. A partir de um vetor de P
    -- amostras (cada uma com N bits), obt�m um vetor de 1 dimens�o concatenado contendo todas
    -- as amostras de forma sequencial.


    -- Tipo que armazena par�metros de configura��o do datapath.
    -- bits_per_sample: n�mero de bits por amostra.
    -- samples_per_block: total de amostras por bloco a serem processadas.
    -- parallel_samples: grau de paralelismo (quantas amostras s�o processadas simultaneamente).


    -- Calcula o n�mero de bits necess�rios para representar a soma de um n�mero arbitr�rio
    -- de valores (number_of_values), cada um com um determinado n�mero de bits (bits_per_value).
    -- O resultado �: bits_per_value + ceil(log2(number_of_values))

    -- Calcula a largura total (n�mero de bits) necess�ria para armazenar o resultado da SAD
    -- completa, ou seja, a soma de todas as diferen�as absolutas das amostras de um par de blocos.


    -- Calcula a largura necess�ria para armazenar uma SAD parcial, considerando apenas as
    -- diferen�as de um subconjunto de amostras processadas em paralelo.


    -- Calcula o n�mero de bits necess�rios para indexar todos os grupos parciais de amostras
    -- dentro de um bloco completo. O n�mero de grupos � (samples_per_block / parallel_samples),
    -- e o resultado � o menor inteiro maior ou igual a log2 desse valor.
    type comandos_t is record
        zi       : std_logic;
        ci       : std_logic;
        cpA      : std_logic;
        cpB      : std_logic;
        zsoma    : std_logic;
        csoma    : std_logic;
        csad_reg : std_logic;
    end record;

    type status_t is record
        menor : std_logic;
    end record;

    type parallel_samples_vector_t is array (natural range <>) of unsigned;
    function to_parallel_samples_vector(param : std_logic_vector; N : positive; P : positive) return parallel_samples_vector_t;
    function to_std_logic_vector(param : parallel_samples_vector_t; N : positive; P : positive) return std_logic_vector;

    type datapath_configuration_t is record
        bits_per_sample   : positive;
        samples_per_block : positive;
        parallel_samples  : positive;
    end record;

    function sum_of_values_length(bits_per_value : positive; number_of_values : positive) return positive;
    function sad_length(bits_per_sample : positive; samples_per_block : positive) return positive;
    function partial_sad_length(bits_per_sample : positive; parallel_samples : positive) return positive;
    function address_length(samples_per_block : positive; parallel_samples : positive) return positive;

end package sad_pack;

package body sad_pack is

    -- Implementa��o da fun��o que converte um std_logic_vector para um vetor de amostras sem sinal.
    -- Entrada:
    --  param : vetor de P*N bits.
    --  N     : n�mero de bits por amostra.
    --  P     : n�mero de amostras.
    -- Sa�da:
    --  Vetor com P elementos do tipo unsigned(N-1 downto 0), extra�dos sequencialmente.
    function to_parallel_samples_vector(param : std_logic_vector; N : positive; P : positive)
    return parallel_samples_vector_t is
        variable return_vector : parallel_samples_vector_t(0 to P - 1)(N - 1 downto 0);
    begin
        for i in return_vector'range loop
            -- Cada amostra � extra�da como uma fatia de N bits do std_logic_vector de entrada (param).
            return_vector(i) := unsigned(param(N * (i + 1) - 1 downto N * i));
        end loop;
        return return_vector;
    end function to_parallel_samples_vector;

    -- Implementa��o da fun��o que concatena um vetor de amostras em um �nico std_logic_vector.
    -- Entrada:
    --  param : vetor de P amostras, cada uma com N bits.
    --  N     : n�mero de bits por amostra.
    --  P     : n�mero de amostras.
    -- Sa�da:
    --  std_logic_vector de P*N bits, resultado da concatena��o de todas as amostras.
    function to_std_logic_vector(param : parallel_samples_vector_t; N : positive; P : positive)
    return std_logic_vector is
        variable return_vector : std_logic_vector(N * P - 1 downto 0);
    begin
        for i in 0 to P - 1 loop
            -- Concatena a amostra 'i' na fatia correspondente do vetor de saida.
            return_vector(N * (i + 1) - 1 downto N * i) := std_logic_vector(param(i));
        end loop;
        return return_vector;
    end function to_std_logic_vector;


    function sum_of_values_length(bits_per_value : positive; number_of_values : positive)
    return positive is
    begin
        return integer(ceil(log2(real(number_of_values)))) + bits_per_value;
    end function sum_of_values_length;


    function sad_length(bits_per_sample : positive; samples_per_block : positive)
    return positive is
    begin
        return sum_of_values_length(bits_per_value => bits_per_sample, number_of_values => samples_per_block);
    end function sad_length;

    
    function partial_sad_length(bits_per_sample : positive; parallel_samples : positive)
    return positive is
    begin
        return sum_of_values_length(bits_per_value => bits_per_sample, number_of_values => parallel_samples);
    end function partial_sad_length;


    function address_length(samples_per_block : positive; parallel_samples : positive)
    return positive is
    begin
        return integer(ceil(log2(real(samples_per_block) / real(parallel_samples))));
    end function address_length;

end package body sad_pack;