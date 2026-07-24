# Alliam Speech token function

This function keeps the Azure Speech subscription key on the server and gives
authenticated Alliam clients a short-lived Azure authorization token.

## Where the real key goes

Do not type the key into `index.js`, `config.js`, an `.env` file, or this README.
From the `C:\Dev\Alliam` directory, run:

```powershell
npx firebase-tools login
npx firebase-tools use spelliam-ad3fd
npx firebase-tools functions:secrets:set AZURE_SPEECH_KEY
```

Firebase will show a private prompt. Paste either Azure **KEY 1** or **KEY 2**
there and press Enter. The key is stored in Google Cloud Secret Manager and is
not written into the project.

Then install dependencies and deploy:

```powershell
Set-Location C:\Dev\Alliam\functions
npm.cmd install
Set-Location C:\Dev\Alliam
npx firebase-tools deploy --only functions:issueSpeechToken
```

After deployment, copy the printed HTTPS function URL into
`microsoftSpeech.tokenEndpoint` in `config.js` and change
`microsoftSpeech.enabled` to `true`.

The Azure region is already configured as `southafricanorth`.
