#!/usr/bin/env python
import sys
sys.path.insert(0, "../")
from plotlib import *
import fire

def _show_benchres(datafile, savefile, legends):
    if isinstance(datafile, str):
        data = np.loadtxt(datafile).reshape([6, len(legends)])
    else:
        data = datafile
    with DataPlt(filename=savefile, figsize=(5,4)) as dp:
        plt.plot(np.arange(10, 28, 3), data/1e3)
        plt.legend(legends)
        plt.yscale('log')
        plt.ylabel(r'$t/ms$')
        plt.xlabel(r'$N$')
        plt.ylim(1e-2, 1e2)

class PltBench():
    def xyz(self):
        qdata = np.loadtxt('projectq/xyz-report.dat').reshape([6, 6])
        ydata = np.loadtxt('yao/xyzcxyz.dat').reshape([6, 6])/1e3
        _show_benchres(np.concatenate([qdata[:,:3], ydata[:,0:6:2]], axis=1), 'comparexyz.png', ['Q-X', 'Q-Y', 'Q-Z', 'Y-X', 'Y-Y', 'Y-Z'])

    def cxyz(self):
        qdata = np.loadtxt('projectq/xyz-report.dat').reshape([6, 6])
        ydata = np.loadtxt('yao/xyzcxyz.dat').reshape([6, 6])/1e3
        _show_benchres(np.concatenate([qdata[:,3:], ydata[:,1:6:2]], axis=1), 'comparecxyz.png', ['Q-CX', 'Q-CY', 'Q-CZ', 'Y-CX', 'Y-CY', 'Y-CZ'])

    def repeatxyz(self):
        _show_benchres('repeatxyz-report.dat', 'projectq-repeatxyz.png', ['X(2-7)', 'Y(2-7)', 'Z(2-7)'])

    def comparer(self):
        data = np.loadtxt('xyz-report.dat').reshape([6, 6])
        datar = np.loadtxt('repeatxyz-report.dat').reshape([6, 3])
        _show_benchres(np.concatenate([data[:,:1], datar[:,:1]/6], axis=1), 'projectq-comparerepeat.png', ['X(2)', 'X(2-7) (time devided by 6)'])

    def hgate(self):
        data = np.loadtxt('h-report.dat').reshape([6, 3])
        data[:,2]/=6
        print(data[:,2]/data[:,0])
        _show_benchres(data, 'projectq-h.png', ['H', 'CH', 'H(2-7) (time / 6)'])

    def toffoli(self):
        _show_benchres('toffoli-report.dat', 'projectq-toffoli.png', ['toffoli'])

    def rot(self):
        _show_benchres('rot-report.dat', 'projectq-rot.png', ['Rx', 'Ry', 'Rz', 'C-Rx', 'C-Ry', 'C-Rz'])

if __name__ == '__main__':
    fire.Fire(PltBench)