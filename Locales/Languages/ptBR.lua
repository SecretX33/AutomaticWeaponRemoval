-- AutomaticWeaponRemoval Localization File
-- Brazilian Portuguese (ptBR)

function AWR:LOAD_LANGUAGE_PTBR()
   AWR_YES = "Sim"
   AWR_NO = "Não"

   -- Interface text
   AWR_ENABLE_ADDON = "Habilitar o addon"
   AWR_ENABLE_ADDON_DESC = "Se desmarcado, o AWR será desativado."
   AWR_LANGUAGE = "Idioma"
   AWR_RELOAD_UI_POPUP_TITLE = "Sua interface precisa ser recarregada para aplicar o novo idioma. Recarregar agora?"
   AWR_SEND_MESSAGE_WHEN_CONTROLLED = "Falar quando for controlado"
   AWR_SEND_MESSAGE_WHEN_CONTROLLED_DESC = "Se desmarcado, você não vai falar nada quando for controlado."
   AWR_CHANNEL = "Canal"
   AWR_CHANNEL_DESC = "Canal onde a mensagem será dita."
   AWR_MESSAGE = "Mensagem"
   AWR_MESSAGE_DESC = "Mensagem que será dita quando você for controlado."
   AWR_CLASS_OPTIONS = "Opções de Classe"
   AWR_BEFORE_MIND_CONTROL = "Quando for controlado"
   AWR_AFTER_MIND_CONTROL = "Depois que o controlado acabar"
   AWR_REMOVE_ONLY_BOW_DESC = "Tirar SOMENTE o arco do Hunter"
   AWR_CANCEL_RF_FROM_PALA_IF_NOT_TANK = "Cancelar RF do Pala caso NÃO seja tank"
   AWR_CANCEL_DIVINE_PLEA_IF_HOLY_PALA = "Cancelar Divine Plea do Pala Holy"
   AWR_REMOVE_WEAPONS_FOR = "Tirar as armas para"

   -- Chat messages
   AWR_ADDON_STILL_LOADING = "Tente novamente depois, o addon ainda está carregando..."

   AWR_HELP1 = "|cff2f6af5As opções do 'AutomaticWeaponRemoval' são as seguintes:|r"
   AWR_HELP2 = "|cff2f6af5/awr toggle:|r Liga e desliga o addon."
   AWR_HELP3 = "|cff2f6af5/awr message \"sua_mensagem\":|r Altera a mensagem que você vai dizer quando for controlado por alguma habilidade."
   AWR_HELP4 = "|cff2f6af5/awr channel \"o_canal\":|r Altera o canal onde você dirá a mensagem."
   AWR_HELP5 = "|cff2f6af5/awr removeweapon:|r Simula um cast de Mind Control em você."
   AWR_HELP6 = "|cff2f6af5/awr count:|r Mostra quantas vezes você já foi controlado."
   AWR_HELP7 = "|cff2f6af5/awr spec:|r Mostra qual é a sua classe e spec."
   AWR_HELP8 = "|cff2f6af5/awr status:|r Mostra se o addon está on/off e o porquê, muito bom pra dar aquela verificada se o addon realmente está ligadoe."
   AWR_HELP9 = "|cff2f6af5/awr version:|r Mostra a versão do addon."

   AWR_TEST_BOSS = "Boss Teste"
   AWR_LADY_NAME = "Lady Deathwhisper"
   AWR_ADDON_MESSAGE_FOR_CONTROL = "%s controlou você."
   AWR_ADDON_MESSAGE_FOR_CONTROL_AND_WEAPON_REMOVAL = "%s controlou você, tirando armas."
   AWR_ADDON_MESSAGE_FOR_CONTROL_AND_WEAPON_REMOVAL_BUT_BAG_WAS_PARTIALLY_FULL = "%s controlou você, mas o AWR só conseguiu tirar algumas de suas armas porque |cfff00a0aSUA MOCHILA ESTÁ QUASE CHEIA!!!|r."
   AWR_ADDON_MESSAGE_FOR_CONTROL_AND_WEAPON_REMOVAL_BUT_BAG_IS_FULL = "%s controlou você, mas o AWR não conseguiu tirar nenhuma das suas armas porque |cfff00a0aSUA MOCHILA ESTÁ COMPLETAMENTE CHEIA!!!|r."

   AWR_SPEC_MESSAGE = "Sua classe é %s e a sua build é %s."

   AWR_REASON_ADDON_IS_OFF = "|cffffe83bstatus:|r o addon está |cffff0000desligado|r porque você desligou ele com o comando \'/awr toggle\'."
   AWR_REASON_DEBUG_MODE_IS_ON = "|cffffe83bstatus:|r o addon está |cff00ff00ligado|r porque o modo de debug está ligado."
   AWR_REASON_INSIDE_VALID_INSTANCE = "|cffffe83bstatus:|r o addon está |cff00ff00ligado|r porque você está dentro de uma instância válida (%s)."
   AWR_REASON_NOT_INSIDE_VALID_INSTANCE = "|cffffe83bstatus:|r o addon está |cffff0000desligado|r porque você não está dentro de uma instância válida."

   AWR_REPORT_COUNT = "você já foi controlado |cffffaf24%d|r vez(es) e você já teve suas armas removidas por esse addon |cffffaf24%d|r vez(es)."

   AWR_CURRENT_MESSAGE = "a mensagem atual é: |cffbffd31%s|r"
   AWR_CHANGED_SAY_MESSAGE = "você agora vai falar |cff48df28%s|r quando você for controlado."
   AWR_MESSAGE_ON = "as mensagens foram |cff00ff00ligadas|r."
   AWR_MESSAGE_OFF = "as mensagens foram |cffff0000desligadas|r."
   AWR_ERROR_MESSAGE_CANNOT_BE_EMPTY = "a mensagem não pode estar vazia."

   AWR_SPEC_TOGGLED_ON_MESSAGE = "A remoção de armas foi |cff00ff00ligada|r para %s %s."     -- spec, class
   AWR_SPEC_TOGGLED_OFF_MESSAGE = "A remoção de armas foi |cffff0000desligada|r para %s %s." -- spec, class

   AWR_SELECTED_CHANNEL = "o canal atual é: |cfff84d13%s|r"
   AWR_CHANGED_CURRENTLY_CHANNEL = "você agora vai mandar as mensagens no |cffff7631%s|r."
   AWR_ERROR_INVALID_CHANNEL = "esse canal não existe, por favor escolha algum dos seguintes canais: %s"

   AWR_SELECTED_LANGUAGE = "o idioma atual é: |cfff84d13%s|r"
   AWR_CHANGED_CURRENTLY_LANGUAGE = "o idioma escolhido foi |cffff7631%s%s|r e será aplicado depois que você recarregar sua interface."
   AWR_ERROR_INVALID_LANGUAGE = "esse idioma não existe, por favor escolha algum dps seguintes idiomas: %s"

   -- Dealing with language load
   AWR_LANGUAGE_LOADED = true
   CH.UnregisterCallback(self, "LOAD_LANGUAGE_ENUS")
   CH.UnregisterCallback(self, "LOAD_LANGUAGE_PTBR")
   CH.callbacks:Fire("LOAD_INTERFACE")
end

CH.RegisterCallback(AWR,"LOAD_LANGUAGE_PTBR")