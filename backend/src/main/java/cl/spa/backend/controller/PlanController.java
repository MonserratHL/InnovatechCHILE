/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package cl.spa.backend.controller;

import cl.spa.backend.model.Plan;
import cl.spa.backend.repository.PlanRepository;
import java.util.List;
import org.springframework.web.bind.annotation.*;

/**
 *
 * @author Duoc
 */

@RestController
@RequestMapping("/api/planes")
@CrossOrigin("*")
public class PlanController {
    
    private final PlanRepository repository;

    public PlanController(PlanRepository repository) {
        this.repository = repository;
    }
    
    @GetMapping
    public List<Plan> getPlanes(){
        return repository.findAll();
    
    }
    
}
