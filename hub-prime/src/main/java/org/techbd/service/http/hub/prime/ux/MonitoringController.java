package org.techbd.service.http.hub.prime.ux;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.techbd.service.http.hub.prime.route.RouteMapping;

import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;

@Controller
@Tag(name = "Tech by Design Hub Monitoring")
public class MonitoringController {
    @SuppressWarnings("unused")
    private static final Logger LOG = LoggerFactory.getLogger(MonitoringController.class.getName());
    // public static final ObjectMapper headersOM = JsonMapper.builder()
    //         .findAndAddModules()
    //         .disable(SerializationFeature.FAIL_ON_EMPTY_BEANS)
    //         .build();

    private final Presentation presentation;

    public MonitoringController(final Presentation presentation) throws Exception {
        this.presentation = presentation;
    }

    @RouteMapping(label = "Monitoring", siblingOrder = 80)
    @GetMapping("/monitoring")
    public String docs() {
        return "redirect:/monitoring/source-monitoring";
    }

    @RouteMapping(label = "Source Monitoring", title = "Source Monitoring", siblingOrder = 30)
    @GetMapping("/monitoring/source-monitoring")
    public String sourceMonitoring(final Model model, final HttpServletRequest request) {
        return presentation.populateModel("page/monitoring/source-monitoring", model, request);
    }   
}
