table dummy_1 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_1;
    }
    size : 4;
}

table dummy_2 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_2;
    }
    size : 4;
}


table dummy_3 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_3;
    }
    size : 4;
}


table dummy_4 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_4;
    }
    size : 4;
}

table dummy_5 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_5;
    }
    size : 4;
}

table dummy_6 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_6;
    }
    size : 4;
}

table dummy_7 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_7;
    }
    size : 4;
}

table dummy_8 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_8;
    }
    size : 4;
}

table dummy_9 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_9;
    }
    size : 4;
}

table dummy_10 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_10;
    }
    size : 4;
}

table dummy_11 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_11;
    }
    size : 4;
}

table dummy_12 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_12;
    }
    size : 4;
}

table dummy_13 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_13;
    }
    size : 4;
}

table dummy_14 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_14;
    }
    size : 4;
}

table dummy_15 {
    reads {
        dpl._repeat : exact;
    }
    actions {
        decrease_15;
    }
    size : 4;
}

control apply_dummy_tables {
    if (dpl._repeat > 0) {
        apply(dummy_1);
    }
    if (dpl._repeat > 0) {
        apply(dummy_2);
    }
    if (dpl._repeat > 0) {
        apply(dummy_3);
    }
    if (dpl._repeat > 0) {
        apply(dummy_4);
    }
    if (dpl._repeat > 0) {
        apply(dummy_5);
    }
    if (dpl._repeat > 0) {
        apply(dummy_6);
    }
    if (dpl._repeat > 0) {
        apply(dummy_7);
    }
    if (dpl._repeat > 0) {
        apply(dummy_8);
    }
    if (dpl._repeat > 0) {
        apply(dummy_9);
    }
    if (dpl._repeat > 0) {
        apply(dummy_10);
    }
    if (dpl._repeat > 0) {
        apply(dummy_11);
    }
    if (dpl._repeat > 0) {
        apply(dummy_12);
    }
    if (dpl._repeat > 0) {
        apply(dummy_13);
    }
    if (dpl._repeat > 0) {
        apply(dummy_14);
    }
    if (dpl._repeat > 0) {
        apply(dummy_15);
    }
}
