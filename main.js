require('update-electron-app')()

const { app, BrowserWindow, ipcMain, dialog } = require('electron')
const fs = require('fs')
const https = require('https')

if (require('electron-squirrel-startup')) return app.quit();

const createWindow = () => {
    const win = new BrowserWindow({
        width: 535,
        height: 768,
        frame: false,
        resizable: false,
        icon: __dirname + '/icons/512x512.png',
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false,
        }
    })

    win.loadFile('ZplPrinter/main.html')
}

app.whenReady().then(() => {
    try {
        const defaultDir = 'C\\\\temp\\\\'
        if (!fs.existsSync(defaultDir)) {
            fs.mkdirSync(defaultDir, { recursive: true })
        }
    } catch (err) {
        console.error(err)
    }

    ipcMain.handle('choose-path', async () => {
        const result = await dialog.showOpenDialog({
            properties: ['openDirectory']
        })
        if (result.canceled || !result.filePaths || result.filePaths.length === 0) {
            return null
        }
        return result.filePaths[0]
    })

    ipcMain.handle('render-zpl', async (_evt, payload) => {
        const { density, width, height, zpl } = payload || {}
        const path = `/v1/printers/${density}dpmm/labels/${width}x${height}/0/`
        const options = {
            hostname: 'api.labelary.com',
            port: 443,
            path,
            method: 'POST',
            headers: {
                'Accept': 'image/png',
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(zpl || '')
            }
        }

        const bodyBuffer = await new Promise((resolve, reject) => {
            const req = https.request(options, (res) => {
                const chunks = []
                res.on('data', (d) => chunks.push(d))
                res.on('end', () => {
                    const buf = Buffer.concat(chunks)
                    if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(buf)
                    } else {
                        reject(new Error(`Labelary HTTP ${res.statusCode}: ${buf.toString('utf8')}`))
                    }
                })
            })
            req.on('error', reject)
            req.write(zpl || '')
            req.end()
        })

        return bodyBuffer.toString('base64')
    })

    createWindow()
})
