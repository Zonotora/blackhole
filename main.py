import numpy as np


def euler_step(y, t, h, f):
    return y + h * f(t, y)


def solve_ode(f, y0, t0, t_end, h):
    t = np.arange(t0, t_end + h, h)
    y = np.zeros(len(t))
    y[0] = y0
    for i in range(1, len(t)):
        y[i] = euler_step(y[i - 1], t[i - 1], h, f)
    return t, y


# Example: y' = -2y, y(0)=1
f = lambda t, y: -2 * y
t, y = solve_ode(f, 1.0, 0, 2, 0.1)


print(t, y)
