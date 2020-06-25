import groovy.json.JsonSlurper
import groovy.json.JsonOutput

def user = new JsonSlurper().parseText(args)

u = security.addUser(
               user.username,
               "", "", "",
               true,
               user.password,
               user.roles)

return JsonOutput.toJson(u)
