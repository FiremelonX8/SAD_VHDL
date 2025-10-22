library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entidade que calcula a diferenca absoluta: |A - B|
entity absolute_difference IS
    generic(
        N : positive := 8
    );
    port(
        input_a  : in  unsigned(N - 1 downto 0);
        input_b  : in  unsigned(N - 1 downto 0);
        abs_diff : out unsigned(N - 1 downto 0)
    );
end entity;

architecture structure OF absolute_difference IS

    -- Sinais para as duas subtracoes possiveis
    signal diff_a_minus_b : unsigned(N - 1 downto 0);
    signal diff_b_minus_a : unsigned(N - 1 downto 0);
    signal select_mux     : std_logic;

    -- Sinais de interface para o MUX (requer std_logic_vector)
    signal mux_in_0       : std_logic_vector(N - 1 downto 0);
    signal mux_in_1       : std_logic_vector(N - 1 downto 0);
    signal mux_out        : std_logic_vector(N - 1 downto 0);

begin

    -- Calcula as duas direcoes da subtracao concorrentemente
    diff_a_minus_b <= input_a - input_b; -- (A - B)
    diff_b_minus_a <= input_b - input_a; -- (B - A)

    -- O sinal de selecao escolhe o resultado positivo (nao-overflow)
    -- '1' seleciona (A - B) se A >= B
    -- '0' seleciona (B - A) se A < B
    select_mux <= '1' when input_a >= input_b else '0';

    -- Converte tipos para a instancia do MUX
    mux_in_0 <= std_logic_vector(diff_b_minus_a);
    mux_in_1 <= std_logic_vector(diff_a_minus_b);

    -- Instancia o MUX para selecionar o resultado correto
    mux_instance : entity work.mux_2to1
        generic map(
            N => N
        )
        port map(
            sel    => select_mux, -- Conectado ao '1' se A >= B
            in_0   => mux_in_0,   -- Resultado de (B - A)
            in_1   => mux_in_1,   -- Resultado de (A - B)
            y      => mux_out
        );

    -- Converte a saida do MUX de volta para o tipo da porta
    abs_diff <= unsigned(mux_out);

end architecture structure;