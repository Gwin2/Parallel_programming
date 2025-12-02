# Математические формулы алгоритма GMRES с предобуславливанием

## Основная система уравнений

$$
A \mathbf{x} = \mathbf{b}
$$

где:
- $A \in \mathbb{R}^{n \times n}$ - разреженная матрица коэффициентов
- $\mathbf{x} \in \mathbb{R}^{n}$ - вектор неизвестных
- $\mathbf{b} \in \mathbb{R}^{n}$ - вектор правой части

## Метод GMRES

### Инициализация

$$
\begin{aligned}
\mathbf{r}_0 &= \mathbf{b} - A\mathbf{x}_0 \\
\beta &= \|\mathbf{r}_0\|_2 \\
\mathbf{v}_1 &= \frac{\mathbf{r}_0}{\beta}
\end{aligned}
$$

### Алгоритм Арнольди

Для $j = 1, 2, \dots, m$:

$$
\begin{aligned}
\mathbf{w} &= A\mathbf{v}_j \\
h_{ij} &= \langle \mathbf{w}, \mathbf{v}_i \rangle \quad \text{для } i = 1, \dots, j \\
\mathbf{w} &= \mathbf{w} - \sum_{i=1}^j h_{ij}\mathbf{v}_i \\
h_{j+1,j} &= \|\mathbf{w}\|_2 \\
\mathbf{v}_{j+1} &= \frac{\mathbf{w}}{h_{j+1,j}}
\end{aligned}
$$

### Матричная форма процесса Арнольди

$$
AV_m = V_{m+1} \tilde{H}_m
$$

где:
- $V_m = [\mathbf{v}_1, \mathbf{v}_2, \dots, \mathbf{v}_m] \in \mathbb{R}^{n \times m}$
- $\tilde{H}_m \in \mathbb{R}^{(m+1) \times m}$ - матрица Хессенберга

### Задача наименьших квадратов

$$
\min_{\mathbf{y} \in \mathbb{R}^m} \|\beta \mathbf{e}_1 - \tilde{H}_m \mathbf{y}\|_2
$$

где $\mathbf{e}_1 = [1, 0, \dots, 0]^T \in \mathbb{R}^{m+1}$

### Обновление решения

$$
\mathbf{x}_m = \mathbf{x}_0 + V_m \mathbf{y}_m
$$

## Предобуславливание

### Левое предобуславливание

$$
M^{-1}A\mathbf{x} = M^{-1}\mathbf{b}
$$

### Правое предобуславливание

$$
AM^{-1}\mathbf{z} = \mathbf{b}, \quad \mathbf{x} = M^{-1}\mathbf{z}
$$

### Двустороннее предобуславливание

$$
M_1^{-1}AM_2^{-1}\mathbf{z} = M_1^{-1}\mathbf{b}, \quad \mathbf{x} = M_2^{-1}\mathbf{z}
$$

## Предобуславливатели

### Диагональный (Jacobi)

$$
M = \text{diag}(A) = \begin{bmatrix}
a_{11} & 0 & \cdots & 0 \\
0 & a_{22} & \cdots & 0 \\
\vdots & \vdots & \ddots & \vdots \\
0 & 0 & \cdots & a_{nn}
\end{bmatrix}
$$

### Блочный диагональный

$$
M = \begin{bmatrix}
A_{11} & 0 & \cdots & 0 \\
0 & A_{22} & \cdots & 0 \\
\vdots & \vdots & \ddots & \vdots \\
0 & 0 & \cdots & A_{kk}
\end{bmatrix}
$$

### Неполное LU разложение (ILU)

$$
A \approx LU
$$

где $L$ - нижняя треугольная, $U$ - верхняя треугольная матрицы

## Критерии сходимости

### Относительная невязка

$$
\frac{\|\mathbf{r}_k\|_2}{\|\mathbf{r}_0\|_2} < \epsilon_{\text{rel}}
$$

### Абсолютная невязка

$$
\|\mathbf{r}_k\|_2 < \epsilon_{\text{abs}}
$$

### Норма невязки

$$
\|\mathbf{r}_k\|_2 = \|\mathbf{b} - A\mathbf{x}_k\|_2
$$

## Свойства матриц

### Число обусловленности

$$
\kappa(A) = \frac{\sigma_{\max}(A)}{\sigma_{\min}(A)} = \|A\|_2 \cdot \|A^{-1}\|_2
$$

### Собственные значения

$$
A\mathbf{v}_i = \lambda_i \mathbf{v}_i
$$

### Спектральный радиус

$$
\rho(A) = \max|\lambda_i(A)|
$$

## Параллельная реализация

### Распределение матрицы

$$
A = \begin{bmatrix}
A_{11} & A_{12} & \cdots & A_{1p} \\
A_{21} & A_{22} & \cdots & A_{2p} \\
\vdots & \vdots & \ddots & \vdots \\
A_{p1} & A_{p2} & \cdots & A_{pp}
\end{bmatrix}
$$

### Локальное матрично-векторное умножение

$$
\mathbf{y}_i = \sum_{j=1}^p A_{ij} \mathbf{x}_j
$$

### Глобальное скалярное произведение

$$
\langle \mathbf{x}, \mathbf{y} \rangle = \sum_{i=1}^p \langle \mathbf{x}_i, \mathbf{y}_i \rangle
$$

## Оценка сложности

### Сложность матрично-векторного умножения

$$
T_{\text{mat-vec}} = O\left(\frac{\text{nnz}}{p} + \text{коммуникация}\right)
$$

### Сложность ортогонализации

$$
T_{\text{orth}} = O\left(\frac{mn^2}{p} + m \cdot \text{коммуникация}\right)
$$

### Общая сложность GMRES

$$
T_{\text{GMRES}} = O\left(m \cdot \frac{\text{nnz} + n^2}{p} + m^2 \cdot \text{коммуникация}\right)
$$

## Уравнение Пуассона

### 1D Лапласиан

$$
A = \begin{bmatrix}
2 & -1 & 0 & \cdots & 0 \\
-1 & 2 & -1 & \cdots & 0 \\
0 & -1 & 2 & \cdots & 0 \\
\vdots & \vdots & \vdots & \ddots & \vdots \\
0 & 0 & 0 & \cdots & 2
\end{bmatrix}
$$

### 2D Лапласиан (5-точечный шаблон)

$$
A = L \otimes I + I \otimes L
$$

где $L$ - 1D Лапласиан, $\otimes$ - произведение Кронекера

### Собственные значения 2D Лапласиана

$$
\lambda_{ij} = 4\left[\sin^2\left(\frac{i\pi}{2(n+1)}\right) + \sin^2\left(\frac{j\pi}{2(n+1)}\right)\right]
$$

## Многосеточные методы

### Сглаживание

$$
\mathbf{x}^{\text{new}} = \mathbf{x}^{\text{old}} + \omega M^{-1}(\mathbf{b} - A\mathbf{x}^{\text{old}})
$$

### Проекция на грубую сетку

$$
A_c = R A_f P
$$

где:
- $R$ - оператор ограничения
- $P$ - оператор интерполяции
- $A_f$ - матрица на мелкой сетке
- $A_c$ - матрица на грубой сетке

## Оценки ошибок

### Априорная оценка

$$
\frac{\|\mathbf{x} - \mathbf{x}_k\|_2}{\|\mathbf{x}\|_2} \leq \kappa(A) \frac{\|\mathbf{r}_k\|_2}{\|\mathbf{b}\|_2}
$$

### Апостериорная оценка

$$
\|\mathbf{x} - \mathbf{x}_k\|_2 \leq \frac{\|\mathbf{r}_k\|_2}{\sigma_{\min}(A)}
$$

## Стабилизация численных методов

### Модифицированный Gram-Schmidt

Для $j = 1, \dots, m$:
$$
\begin{aligned}
\mathbf{w} &= A\mathbf{v}_j \\
\text{для } i &= 1, \dots, j: \\
&\quad h_{ij} = \langle \mathbf{w}, \mathbf{v}_i \rangle \\
&\quad \mathbf{w} = \mathbf{w} - h_{ij}\mathbf{v}_i \\
h_{j+1,j} &= \|\mathbf{w}\|_2 \\
\mathbf{v}_{j+1} &= \frac{\mathbf{w}}{h_{j+1,j}}
\end{aligned}
$$

### Перезапуск GMRES(m)

После $m$ итераций:
$$
\begin{aligned}
\mathbf{x}_m &= \mathbf{x}_0 + V_m \mathbf{y}_m \\
\mathbf{r}_m &= \mathbf{b} - A\mathbf{x}_m \\
\text{перезапуск с } &\mathbf{x}_0 = \mathbf{x}_m
\end{aligned}
$$

## Теоремы сходимости

### Теорема (сходимость GMRES)

Если $A$ положительно определена, то GMRES сходится монотонно:

$$
\|\mathbf{r}_k\|_2 \leq \|\mathbf{r}_{k-1}\|_2
$$

### Оценка сходимости через многочлены

$$
\|\mathbf{r}_k\|_2 = \min_{p \in \mathcal{P}_k} \|p(A)\mathbf{r}_0\|_2
$$

где $\mathcal{P}_k$ - множество многочленов степени $k$ с $p(0) = 1$

## Практические формулы

### Выбор параметров перезапуска

$$
m_{\text{opt}} = \min\left(50, \sqrt{\frac{\text{доступная память}}{8n}}\right)
$$

### Критерий останова

$$
\frac{\|\mathbf{r}_k\|_2}{\|\mathbf{b}\|_2} < \max\left(\epsilon_{\text{mach}}, \epsilon_{\text{user}}\right)
$$

### Оценка времени решения

$$
T_{\text{total}} = T_{\text{setup}} + k \cdot T_{\text{iteration}}
$$

где:
- $T_{\text{setup}}$ - время настройки предобуславливателя
- $T_{\text{iteration}}$ - время одной итерации GMRES
- $k$ - количество итераций

## Заключение

Эти формулы представляют математическую основу метода GMRES с предобуславливанием и могут использоваться для анализа сходимости, оценки сложности и разработки эффективных параллельных реализаций.